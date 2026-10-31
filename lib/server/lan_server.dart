import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/constants.dart';
import '../core/models/access_mode.dart';
import '../core/models/chat_message.dart';
import '../core/models/peer.dart';
import '../core/protocol/ws_event.dart';
import '../storage/file_store.dart';
import '../storage/history_store.dart';
import 'client_connection.dart';
import 'http_utils.dart';

const _uuid = Uuid();

/// 主机内置服务：HTTP 接口 + WebSocket `/ws` + 网页托管 + 访问控制。
///
/// 所有消息由主机统一分配 ID 与时间戳、写入历史并广播给已加入的连接。
class LanServer extends ChangeNotifier {
  LanServer({
    required this.host,
    required this.history,
    required this.files,
    required AccessMode accessMode,
  }) : _accessMode = accessMode;

  /// 主机自身在会话中的身份。
  final Peer host;
  final HistoryStore history;
  final FileStore files;

  HttpServer? _server;
  String _indexHtml = '';
  AccessMode _accessMode;

  final Map<String, ClientConnection> _connections = {};

  /// 访问令牌 → 连接 ID。令牌在 welcome 时下发，连接关闭即失效。
  final Map<String, String> _tokens = {};

  /// 本次服务运行期间已被主机同意的设备，断线重连无需再次确认。
  final Set<String> _approvedDevices = {};

  /// 待确认的加入请求，键为设备 ID（同一设备的多个连接合并为一个请求）。
  final Map<String, JoinRequest> _pending = {};

  final List<ChatMessage> _messages = [];
  final Map<String, FileMeta> _fileIndex = {};

  int? get port => _server?.port;
  bool get running => _server != null;
  AccessMode get accessMode => _accessMode;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<JoinRequest> get pendingRequests => _pending.values.toList()
    ..sort((a, b) => a.requestedAt.compareTo(b.requestedAt));

  /// 在线设备：主机 + 已加入的设备（按设备 ID 去重）。
  List<Peer> get peers {
    final byDevice = <String, Peer>{};
    for (final c in _connections.values) {
      if (c.isJoined && c.peer != null) byDevice[c.peer!.id] = c.peer!;
    }
    byDevice.remove(host.id);
    return [host, ...byDevice.values];
  }

  // ---------------------------------------------------------------------------
  // 生命周期

  Future<int> start() async {
    if (_server != null) return _server!.port;
    _indexHtml = await rootBundle.loadString('assets/web/index.html');
    final loaded = await history.load();
    _messages
      ..clear()
      ..addAll(loaded);
    _fileIndex.clear();
    for (final m in loaded) {
      if (m.file != null) _fileIndex[m.file!.id] = m.file!;
    }

    final handler = const Pipeline()
        .addMiddleware(_errorMiddleware())
        .addHandler(_buildRouter().call);
    try {
      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        LanChatConstants.preferredPort,
        shared: false,
      );
    } on SocketException {
      // 首选端口被占用时由系统分配端口。
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 0);
    }
    _server!.autoCompress = false;
    _server!.idleTimeout = const Duration(seconds: 120);
    notifyListeners();
    return _server!.port;
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    final connections = _connections.values.toList();
    _connections.clear();
    _tokens.clear();
    _pending.clear();
    _approvedDevices.clear();
    for (final c in connections) {
      c.send(const WsEvent(WsEventType.error, {'message': '主机已结束会话'}));
      await c.close(ws_status.goingAway, 'host stopped');
    }
    await server?.close(force: true);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 访问控制

  void setAccessMode(AccessMode mode) {
    if (mode == _accessMode) return;
    _accessMode = mode;
    if (mode == AccessMode.open) {
      // 切换为无需认证时，所有等待中的请求直接放行。
      for (final deviceId in _pending.keys.toList()) {
        approve(deviceId);
      }
    }
    notifyListeners();
  }

  void approve(String deviceId) {
    _pending.remove(deviceId);
    _approvedDevices.add(deviceId);
    for (final c in _connections.values.toList()) {
      if (c.state == ConnectionState.pending && c.peer?.id == deviceId) {
        _join(c);
      }
    }
    notifyListeners();
  }

  void reject(String deviceId) {
    _pending.remove(deviceId);
    for (final c in _connections.values.toList()) {
      if (c.state == ConnectionState.pending && c.peer?.id == deviceId) {
        c.send(const WsEvent(WsEventType.rejected, {'reason': '主机拒绝了你的加入请求'}));
        _connections.remove(c.id);
        unawaited(c.close(ws_status.policyViolation, 'rejected'));
      }
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 主机自身发送

  Future<ChatMessage> postText(String text) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      kind: MessageKind.text,
      sender: host,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      text: text,
    );
    await _publish(message);
    return message;
  }

  /// 主机发送文件：复制进文件存储后广播。
  Future<ChatMessage> postFile({
    required String name,
    required Stream<List<int>> source,
    void Function(int written)? onProgress,
  }) async {
    final id = _uuid.v4();
    final safeName = FileStore.sanitizeFileName(name);
    final placeholder = FileMeta(id: id, name: safeName, size: 0, mime: '');
    final saved = await files.importStream(placeholder, source, onProgress: onProgress);
    final meta = FileMeta(
      id: id,
      name: safeName,
      size: await saved.length(),
      mime: lookupMimeType(safeName) ?? 'application/octet-stream',
    );
    final message = ChatMessage(
      id: _uuid.v4(),
      kind: MessageKind.file,
      sender: host,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      file: meta,
    );
    await _publish(message);
    return message;
  }

  /// 清空聊天记录与已存储的文件，并通知所有客户端。
  Future<void> clearHistory() async {
    final fileIds = _fileIndex.keys.toList();
    _messages.clear();
    _fileIndex.clear();
    await history.clear();
    for (final id in fileIds) {
      final dir = files.dirFor(id);
      if (await dir.exists()) await dir.delete(recursive: true);
    }
    _broadcast(const WsEvent(WsEventType.history, <Object>[]));
    notifyListeners();
  }

  Future<void> _publish(ChatMessage message) async {
    _messages.add(message);
    if (message.file != null) _fileIndex[message.file!.id] = message.file!;
    await history.append(message);
    _broadcast(WsEvent(WsEventType.message, message.toJson()));
    notifyListeners();
  }

  void _broadcast(WsEvent event) {
    for (final c in _connections.values) {
      if (c.isJoined) c.send(event);
    }
  }

  void _broadcastPeers() {
    _broadcast(WsEvent(
      WsEventType.peers,
      peers.map((p) => p.toJson()).toList(),
    ));
  }

  // ---------------------------------------------------------------------------
  // HTTP 路由

  Router _buildRouter() {
    final router = Router(notFoundHandler: (_) => jsonError(404, 'Not Found'));
    router.get('/', _serveIndex);
    router.get('/index.html', _serveIndex);
    router.get('/api/info', _serveInfo);
    router.get('/api/history', _serveHistory);
    router.post('/api/upload', _handleUpload);
    router.get('/api/files/<id>', _serveFile);
    router.get('/ws', _handleWebSocket);
    return router;
  }

  Middleware _errorMiddleware() => (inner) => (request) async {
        try {
          return await inner(request);
        } on HijackException {
          rethrow;
        } catch (e, st) {
          debugPrint('请求处理失败 ${request.method} ${request.url}: $e\n$st');
          return jsonError(500, '服务器内部错误');
        }
      };

  Response _serveIndex(Request request) => Response.ok(
        _indexHtml,
        headers: {
          HttpHeaders.contentTypeHeader: 'text/html; charset=utf-8',
          HttpHeaders.cacheControlHeader: 'no-cache',
        },
      );

  /// 公开的主机信息（不含聊天数据），供客户端手动输入地址时校验。
  Response _serveInfo(Request request) => jsonResponse({
        'app': 'lanchat',
        'version': LanChatConstants.protocolVersion,
        'name': host.name,
        'deviceId': host.id,
        'accessMode': _accessMode.name,
      });

  /// 根据令牌找到已加入的连接对应的设备；无效时返回 null。
  Peer? _authorize(Request request) {
    final token = readToken(request);
    if (token == null) return null;
    final connection = _connections[_tokens[token]];
    if (connection == null || !connection.isJoined) return null;
    return connection.peer;
  }

  Response _serveHistory(Request request) {
    if (_authorize(request) == null) return jsonError(401, '未授权');
    final limit = int.tryParse(request.url.queryParameters['limit'] ?? '') ??
        LanChatConstants.historyLimit;
    final start = _messages.length > limit ? _messages.length - limit : 0;
    return jsonResponse(
      _messages.sublist(start).map((m) => m.toJson()).toList(),
    );
  }

  /// `POST /api/upload`：multipart/form-data，取第一个带 filename 的分段。
  /// 可选查询参数 `name` 指定 UTF-8 文件名（避免各客户端分段头编码差异）。
  Future<Response> _handleUpload(Request request) async {
    final sender = _authorize(request);
    if (sender == null) return jsonError(401, '未授权');
    final boundary = multipartBoundary(request);
    if (boundary == null) return jsonError(400, '需要 multipart/form-data');

    final fileId = _uuid.v4();
    File? part;
    try {
      // request.read() 在某些平台下运行时类型是 Stream<Uint8List>，
      // 直接 transform 会因泛型协变触发 `MimeMultipartTransformer` 类型不匹配；
      // 显式 cast<List<int>>() 统一运行时类型后再接入。
      final parts = request
          .read()
          .cast<List<int>>()
          .transform(MimeMultipartTransformer(boundary));
      await for (final p in parts) {
        final disposition = parseContentDisposition(p.headers['content-disposition']);
        if (part != null || disposition.filename == null) {
          await p.drain<void>();
          continue;
        }
        final rawName = request.url.queryParameters['name'] ??
            disposition.filename!.replaceAll('%22', '"');
        final name = FileStore.sanitizeFileName(rawName);
        part = await files.createPartFile(fileId);
        final sink = part.openWrite();
        var size = 0;
        try {
          await for (final chunk in p) {
            sink.add(chunk);
            size += chunk.length;
          }
          await sink.flush();
        } finally {
          await sink.close();
        }
        final partType = p.headers['content-type'];
        final meta = FileMeta(
          id: fileId,
          name: name,
          size: size,
          mime: lookupMimeType(name) ??
              (partType != null && partType.isNotEmpty ? partType : 'application/octet-stream'),
        );
        await files.commit(part, meta);
        part = null;
        final message = ChatMessage(
          id: _uuid.v4(),
          kind: MessageKind.file,
          sender: sender,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          file: meta,
        );
        await _publish(message);
        return jsonResponse(message.toJson());
      }
      return jsonError(400, '未找到文件分段');
    } catch (e) {
      debugPrint('上传失败：$e');
      final dir = files.dirFor(fileId);
      if (await dir.exists()) await dir.delete(recursive: true);
      return jsonError(400, '上传失败');
    }
  }

  /// `GET /api/files/<id>`：支持单段 Range；`?download=1` 以附件形式下载。
  Future<Response> _serveFile(Request request, String id) async {
    if (_authorize(request) == null) return jsonError(401, '未授权');
    final meta = _fileIndex[id];
    if (meta == null) return jsonError(404, '文件不存在');
    final file = files.fileFor(meta);
    if (!await file.exists()) return jsonError(404, '文件已被删除');

    final size = await file.length();
    final asAttachment = request.url.queryParameters['download'] == '1';
    final headers = {
      HttpHeaders.contentTypeHeader: meta.mime,
      HttpHeaders.acceptRangesHeader: 'bytes',
      HttpHeaders.cacheControlHeader: 'private, max-age=3600',
      'content-disposition': contentDisposition(meta.name, inline: !asAttachment),
    };

    ByteRange? range;
    try {
      range = parseRange(request.headers[HttpHeaders.rangeHeader], size);
    } on RangeError {
      return Response(416, headers: {HttpHeaders.contentRangeHeader: 'bytes */$size'});
    }
    if (range == null) {
      return Response.ok(
        file.openRead(),
        headers: {...headers, HttpHeaders.contentLengthHeader: '$size'},
      );
    }
    return Response(
      206,
      body: file.openRead(range.start, range.end + 1),
      headers: {
        ...headers,
        HttpHeaders.contentLengthHeader: '${range.length}',
        HttpHeaders.contentRangeHeader: 'bytes ${range.start}-${range.end}/$size',
      },
    );
  }

  // ---------------------------------------------------------------------------
  // WebSocket

  FutureOr<Response> _handleWebSocket(Request request) {
    final info = request.context['shelf.io.connection_info'];
    final remote = info is HttpConnectionInfo ? info.remoteAddress.address : '';
    final handler = webSocketHandler(
      (WebSocketChannel channel, String? _) => _onConnect(channel, remote),
      pingInterval: LanChatConstants.pingInterval,
    );
    return handler(request);
  }

  void _onConnect(WebSocketChannel channel, String remoteAddress) {
    if (_server == null) {
      unawaited(channel.sink.close(ws_status.goingAway));
      return;
    }
    final connection = ClientConnection(
      id: _uuid.v4(),
      channel: channel,
      remoteAddress: remoteAddress,
    );
    _connections[connection.id] = connection;
    connection.helloTimer = Timer(LanChatConstants.helloTimeout, () {
      if (connection.state == ConnectionState.handshaking) {
        _connections.remove(connection.id);
        unawaited(connection.close(ws_status.policyViolation, 'hello timeout'));
      }
    });
    channel.stream.listen(
      (frame) => _onFrame(connection, frame),
      onDone: () => _onDisconnect(connection),
      onError: (Object _) => _onDisconnect(connection),
      cancelOnError: true,
    );
  }

  void _onFrame(ClientConnection connection, Object? frame) {
    final event = WsEvent.tryDecode(frame);
    if (event == null) return;
    switch (event.type) {
      case WsEventType.hello when connection.state == ConnectionState.handshaking:
        _onHello(connection, event.dataMap);
      case WsEventType.message when connection.isJoined:
        final text = (event.dataMap['text'] as String?)?.trim() ?? '';
        if (text.isEmpty) return;
        if (text.length > 20000) {
          connection.send(const WsEvent(WsEventType.error, {'message': '消息过长'}));
          return;
        }
        unawaited(_publish(ChatMessage(
          id: _uuid.v4(),
          kind: MessageKind.text,
          sender: connection.peer!,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          text: text,
        )));
      default:
        break;
    }
  }

  void _onHello(ClientConnection connection, Map<String, dynamic> data) {
    connection.helloTimer?.cancel();
    final rawId = (data['deviceId'] as String? ?? '').trim();
    final deviceId = FileStore.sanitizeId(rawId);
    final rawName = (data['name'] as String? ?? '').trim();
    final platform = PeerPlatform.parse(data['platform']);
    connection.peer = Peer(
      id: deviceId == 'invalid' ? connection.id : deviceId,
      name: rawName.isEmpty
          ? '设备 ${connection.remoteAddress}'
          : (rawName.length > 32 ? rawName.substring(0, 32) : rawName),
      // 客户端不允许冒充主机身份。
      platform: platform == PeerPlatform.host ? PeerPlatform.app : platform,
    );

    final peer = connection.peer!;
    if (_accessMode == AccessMode.open || _approvedDevices.contains(peer.id)) {
      _join(connection);
      return;
    }
    connection.state = ConnectionState.pending;
    connection.send(const WsEvent(WsEventType.pending, {'message': '等待主机确认'}));
    _pending.putIfAbsent(
      peer.id,
      () => JoinRequest(
        connectionId: connection.id,
        peer: peer,
        remoteAddress: connection.remoteAddress,
      ),
    );
    notifyListeners();
  }

  void _join(ClientConnection connection) {
    connection.state = ConnectionState.joined;
    final token = _uuid.v4();
    _tokens[token] = connection.id;
    connection.send(WsEvent(WsEventType.welcome, {
      'self': connection.peer!.toJson(),
      'host': host.toJson(),
      'token': token,
      'accessMode': _accessMode.name,
    }));
    final start = _messages.length > LanChatConstants.historyLimit
        ? _messages.length - LanChatConstants.historyLimit
        : 0;
    connection.send(WsEvent(
      WsEventType.history,
      _messages.sublist(start).map((m) => m.toJson()).toList(),
    ));
    _broadcastPeers();
    notifyListeners();
  }

  void _onDisconnect(ClientConnection connection) {
    connection.helloTimer?.cancel();
    if (_connections.remove(connection.id) == null) return;
    _tokens.removeWhere((_, connectionId) => connectionId == connection.id);
    final deviceId = connection.peer?.id;
    if (connection.state == ConnectionState.pending && deviceId != null) {
      final stillWaiting = _connections.values.any(
        (c) => c.state == ConnectionState.pending && c.peer?.id == deviceId,
      );
      if (!stillWaiting) _pending.remove(deviceId);
    }
    if (connection.isJoined) _broadcastPeers();
    notifyListeners();
  }
}
