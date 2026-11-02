import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/models/access_mode.dart';
import '../core/models/chat_message.dart';
import '../core/models/peer.dart';
import '../core/session/chat_session.dart';
import '../discovery/lan_discovery.dart';
import '../storage/app_storage.dart';
import 'client_connection.dart';
import 'lan_server.dart';
import 'network_addresses.dart';

/// 主机会话：启动内置服务与 mDNS 广播，供聊天页和首页（访问地址/二维码）使用。
class HostSession extends ChatSession {
  HostSession._(this._storage, this.server);

  final AppStorage _storage;
  final LanServer server;
  final LanBroadcaster _broadcaster = LanBroadcaster();
  final List<OutgoingTransfer> _outgoing = [];
  SessionStatus _status = SessionStatus.connecting;
  String? _statusMessage;
  List<String> _addresses = const [];

  /// 本机可访问的局域网 IPv4 地址，第一个为首选。
  List<String> get addresses => _addresses;

  /// 首选网页访问地址，用于二维码。
  String? get primaryUrl => _addresses.isEmpty || server.port == null
      ? null
      : 'http://${_addresses.first}:${server.port}';

  List<String> get urls => server.port == null
      ? const []
      : _addresses.map((a) => 'http://$a:${server.port}').toList();

  AccessMode get accessMode => server.accessMode;
  List<JoinRequest> get pendingRequests => server.pendingRequests;

  /// 创建并启动主机会话；端口监听失败时抛出异常。
  static Future<HostSession> start(AppStorage storage) async {
    await storage.history.archive();
    final settings = storage.settings;
    final server = LanServer(
      host: Peer(
        id: settings.deviceId,
        name: settings.deviceName,
        platform: PeerPlatform.host,
      ),
      history: storage.history,
      files: storage.files,
      accessMode: settings.accessMode,
    );
    final session = HostSession._(storage, server);
    await session._start();
    return session;
  }

  Future<void> _start() async {
    server.addListener(notifyListeners);
    final port = await server.start();
    _status = SessionStatus.connected;
    _addresses = await lanIPv4Addresses();
    try {
      await _broadcaster.start(
        deviceId: server.host.id,
        deviceName: server.host.name,
        port: port,
      );
    } catch (e) {
      // 广播失败不影响通过 IP/二维码访问。
      _statusMessage = '设备发现广播失败，其他设备可通过 IP 地址访问';
      debugPrint('mDNS 广播失败：$e');
    }
    notifyListeners();
  }

  /// 网络切换（例如开启热点）后刷新访问地址。
  Future<void> refreshAddresses() async {
    _addresses = await lanIPv4Addresses();
    notifyListeners();
  }

  Future<void> setAccessMode(AccessMode mode) async {
    server.setAccessMode(mode);
    await _storage.settings.setAccessMode(mode);
  }

  void approve(String deviceId) => server.approve(deviceId);

  void reject(String deviceId) => server.reject(deviceId);

  Future<void> clearHistory() => server.clearHistory();

  @override
  Peer get self => server.host;

  @override
  String get title => server.host.name;

  @override
  bool get isHost => true;

  @override
  SessionStatus get status => _status;

  @override
  String? get statusMessage => _statusMessage;

  @override
  List<ChatMessage> get messages => server.messages;

  @override
  List<Peer> get peers => server.peers;

  @override
  List<OutgoingTransfer> get outgoing => List.unmodifiable(_outgoing);

  @override
  Map<String, double> get downloads => const {};

  @override
  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await server.postText(trimmed);
  }

  @override
  Future<void> sendFile(LocalFileSource file) async {
    final transfer = OutgoingTransfer(
      id: const Uuid().v4(),
      name: file.name,
      size: file.size,
    );
    _outgoing.add(transfer);
    notifyListeners();
    try {
      await server.postFile(
        name: file.name,
        source: file.openRead(),
        onProgress: (written) {
          if (transfer.update(written)) notifyListeners();
        },
      );
      _outgoing.remove(transfer);
    } catch (e) {
      transfer.error = '保存失败：$e';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// 移除失败的发送记录。
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
  Future<String> ensureLocal(FileMeta file) async {
    final path = await localPathFor(file);
    if (path == null) throw StateError('文件已被删除');
    return path;
  }

  @override
  Future<void> close() async {
    if (_status == SessionStatus.closed) return;
    _status = SessionStatus.closed;
    server.removeListener(notifyListeners);
    await _broadcaster.stop();
    await server.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }
}
