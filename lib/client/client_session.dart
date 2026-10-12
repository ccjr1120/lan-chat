import 'dart:async';
import 'dart:io';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../core/models/chat_message.dart';
import '../core/models/peer.dart';
import '../core/protocol/ws_event.dart';
import '../core/session/chat_session.dart';
import '../storage/app_storage.dart';
import 'transfer_client.dart';

/// 客户端会话：连接主机 `/ws`，断线自动重连；文件经 HTTP 上传下载。
///
/// 聊天记录以主机为准，每次加入会话时由 `history` 事件下发，客户端不单独持久化。
class ClientSession extends ChatSession {
  ClientSession({
    required AppStorage storage,
    required this.host,
    required this.port,
    String? hostName,
  })  : _storage = storage,
        _title = hostName ?? '$host:$port',
        _transfer = TransferClient('http://${_formatHost(host)}:$port'),
        _self = Peer(
          id: storage.settings.deviceId,
          name: storage.settings.deviceName,
          platform: PeerPlatform.app,
        );

  final AppStorage _storage;
  final String host;
  final int port;
  final TransferClient _transfer;
  Peer _self;
  String _title;

  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  SessionStatus _status = SessionStatus.disconnected;
  String? _statusMessage;
  final List<ChatMessage> _messages = [];
  final Set<String> _messageIds = {};
  List<Peer> _peers = const [];
  final List<OutgoingTransfer> _outgoing = [];
  final Map<String, double> _downloads = {};
  final Map<String, Future<String>> _inflightDownloads = {};

  String get address => '${_formatHost(host)}:$port';

  /// 主机网页地址，可提示用户在电脑浏览器打开。
  String get webUrl => _transfer.baseUrl;

  static String _formatHost(String host) => host.contains(':') ? '[$host]' : host;

  // ---------------------------------------------------------------------------
  // 连接管理

  /// 建立连接。首次调用会先校验地址是否为本应用主机。
  Future<void> connect() async {
    if (_status == SessionStatus.closed || _status == SessionStatus.rejected) return;
    _reconnectTimer?.cancel();
    _setStatus(SessionStatus.connecting, '正在连接 $address');
    try {
      if (_reconnectAttempts == 0) {
        final info = await _transfer.info();
        final name = info['name'];
        if (name is String && name.isNotEmpty) _title = name;
      }
      final uri = Uri.parse('ws://$address/ws');
      final channel = IOWebSocketChannel.connect(
        uri,
        connectTimeout: const Duration(seconds: 8),
        pingInterval: const Duration(seconds: 20),
      );
      await channel.ready;
      if (_status == SessionStatus.closed) {
        await channel.sink.close(ws_status.normalClosure);
        return;
      }
      _channel = channel;
      _subscription = channel.stream.listen(
        _onFrame,
        onDone: () => _onConnectionLost(channel.closeReason),
        onError: (Object e) => _onConnectionLost(e.toString()),
        cancelOnError: true,
      );
      channel.sink.add(WsEvent(WsEventType.hello, {
        'deviceId': _self.id,
        'name': _storage.settings.deviceName,
        'platform': PeerPlatform.app.name,
      }).encode());
    } catch (e) {
      final message = e is FormatException ? e.message : TransferClient.describe(e);
      _onConnectionLost(_reconnectAttempts == 0 ? message : null);
    }
  }

  void _onConnectionLost(String? reason) {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _transfer.token = null;
    if (_status == SessionStatus.closed || _status == SessionStatus.rejected) return;
    _peers = const [];
    _reconnectAttempts++;
    // 退避重连：1s、2s、4s … 最长 15s。
    final delay = Duration(seconds: (1 << (_reconnectAttempts - 1).clamp(0, 4)).clamp(1, 15));
    _setStatus(
      SessionStatus.disconnected,
      '${reason == null || reason.isEmpty ? '连接已断开' : reason}，${delay.inSeconds} 秒后重试',
    );
    _reconnectTimer = Timer(delay, () => unawaited(connect()));
  }

  /// 立即重试连接。
  void retryNow() {
    if (_status == SessionStatus.disconnected) unawaited(connect());
  }

  void _onFrame(dynamic frame) {
    final event = WsEvent.tryDecode(frame);
    if (event == null) return;
    switch (event.type) {
      case WsEventType.pending:
        _setStatus(SessionStatus.pending, '等待主机确认');
      case WsEventType.welcome:
        final data = event.dataMap;
        _transfer.token = data['token'] as String?;
        final self = data['self'];
        if (self is Map<String, dynamic>) _self = Peer.fromJson(self);
        final host = data['host'];
        if (host is Map<String, dynamic>) _title = Peer.fromJson(host).name;
        _reconnectAttempts = 0;
        _setStatus(SessionStatus.connected, null);
      case WsEventType.rejected:
        final reason = event.dataMap['reason'] as String? ?? '主机拒绝了加入请求';
        _status = SessionStatus.rejected;
        _statusMessage = reason;
        unawaited(_channel?.sink.close(ws_status.normalClosure));
        notifyListeners();
      case WsEventType.peers:
        _peers = event.dataList.map(Peer.fromJson).toList();
        notifyListeners();
      case WsEventType.history:
        _messages.clear();
        _messageIds.clear();
        for (final json in event.dataList) {
          _addMessage(ChatMessage.fromJson(json));
        }
        notifyListeners();
      case WsEventType.message:
        _addMessage(ChatMessage.fromJson(event.dataMap));
        notifyListeners();
      case WsEventType.error:
        _statusMessage = event.dataMap['message'] as String?;
        notifyListeners();
    }
  }

  void _addMessage(ChatMessage message) {
    if (_messageIds.add(message.id)) _messages.add(message);
  }

  void _setStatus(SessionStatus status, String? message) {
    _status = status;
    _statusMessage = message;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // ChatSession

  @override
  Peer get self => _self;

  @override
  String get title => _title;

  @override
  bool get isHost => false;

  @override
  SessionStatus get status => _status;

  @override
  String? get statusMessage => _statusMessage;

  @override
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  @override
  List<Peer> get peers => _peers;

  @override
  List<OutgoingTransfer> get outgoing => List.unmodifiable(_outgoing);

  @override
  Map<String, double> get downloads => Map.unmodifiable(_downloads);

  @override
  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final channel = _channel;
    if (channel == null || _status != SessionStatus.connected) {
      throw StateError('尚未连接到主机');
    }
    channel.sink.add(WsEvent(WsEventType.message, {'text': trimmed}).encode());
  }

  @override
  Future<void> sendFile(LocalFileSource file) async {
    if (_status != SessionStatus.connected) throw StateError('尚未连接到主机');
    final transfer = OutgoingTransfer(id: const Uuid().v4(), name: file.name, size: file.size);
    _outgoing.add(transfer);
    notifyListeners();
    try {
      final message = await _transfer.upload(file, onProgress: (sent, total) {
        if (transfer.update(sent)) notifyListeners();
      });
      _outgoing.remove(transfer);
      // 主机也会通过 WS 广播该消息，按 ID 去重。
      _addMessage(message);
    } catch (e) {
      transfer.error = TransferClient.describe(e);
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  void dismissTransfer(OutgoingTransfer transfer) {
    _outgoing.remove(transfer);
    notifyListeners();
  }

  @override
  Future<String?> localPathFor(FileMeta file) async {
    final f = _storage.files.fileFor(file);
    return await f.exists() ? f.path : null;
  }

  @override
  Future<String> ensureLocal(FileMeta file) {
    return _inflightDownloads.putIfAbsent(file.id, () async {
      try {
        final existing = await localPathFor(file);
        if (existing != null) return existing;
        if (_transfer.token == null) throw StateError('尚未连接到主机，无法下载');
        final part = await _storage.files.createPartFile(file.id);
        _downloads[file.id] = 0;
        notifyListeners();
        await _transfer.download(file, part.path, onProgress: (received, total) {
          final size = total > 0 ? total : file.size;
          final value = size > 0 ? (received / size).clamp(0, 1).toDouble() : 0.0;
          final previous = _downloads[file.id] ?? 0;
          // 进度每增长 1% 才更新并刷新界面。
          if (value - previous >= 0.01 || value >= 1) {
            _downloads[file.id] = value;
            notifyListeners();
          }
        });
        final saved = await _storage.files.commit(part, file);
        return saved.path;
      } catch (e) {
        if (e is StateError) rethrow;
        throw HttpException(TransferClient.describe(e));
      } finally {
        _downloads.remove(file.id);
        unawaited(_inflightDownloads.remove(file.id));
        notifyListeners();
      }
    });
  }

  @override
  Future<void> close() async {
    if (_status == SessionStatus.closed) return;
    _status = SessionStatus.closed;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close(ws_status.normalClosure);
    _channel = null;
    _transfer.close();
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }
}
