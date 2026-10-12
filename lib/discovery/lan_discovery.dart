import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';

/// 局域网中被发现的主机。
class DiscoveredHost {
  const DiscoveredHost({
    required this.serviceName,
    required this.name,
    required this.host,
    required this.port,
    this.deviceId,
  });

  /// mDNS 服务实例名，作为发现列表的唯一键。
  final String serviceName;

  /// 主机设备名（TXT `name`）。
  final String name;
  final String host;
  final int port;
  final String? deviceId;

  String get address => '$host:$port';
}

/// 主机端 mDNS 广播：服务类型 [LanChatConstants.serviceType]。
class LanBroadcaster {
  BonsoirBroadcast? _broadcast;

  Future<void> start({
    required String deviceId,
    required String deviceName,
    required int port,
  }) async {
    await stop();
    final service = BonsoirService(
      name: 'LanChat-${deviceId.substring(0, 8)}',
      type: LanChatConstants.serviceType,
      port: port,
      attributes: {
        'id': deviceId,
        'name': _truncateUtf8(deviceName, 200),
        'v': LanChatConstants.protocolVersion,
      },
    );
    final broadcast = BonsoirBroadcast(service: service);
    _broadcast = broadcast;
    await broadcast.initialize();
    await broadcast.start();
  }

  Future<void> stop() async {
    final broadcast = _broadcast;
    _broadcast = null;
    if (broadcast != null && !broadcast.isStopped) {
      try {
        await broadcast.stop();
      } catch (e) {
        debugPrint('停止 mDNS 广播失败：$e');
      }
    }
  }

  static String _truncateUtf8(String value, int maxChars) =>
      value.length > maxChars ? value.substring(0, maxChars) : value;
}

/// 客户端 mDNS 发现，解析成功的主机通过 [hosts] 暴露。
class LanDiscovery extends ChangeNotifier {
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _subscription;
  final Map<String, DiscoveredHost> _hosts = {};

  /// 自己作为主机时需要从列表中排除的设备 ID。
  String? ownDeviceId;

  bool _running = false;
  String? _error;

  bool get running => _running;
  String? get error => _error;
  List<DiscoveredHost> get hosts => _hosts.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  Future<void> start() async {
    if (_running) return;
    _error = null;
    _hosts.clear();
    try {
      final discovery = BonsoirDiscovery(type: LanChatConstants.serviceType);
      _discovery = discovery;
      await discovery.initialize();
      _subscription = discovery.eventStream?.listen(_onEvent);
      await discovery.start();
      _running = true;
    } catch (e) {
      _error = '设备发现启动失败：$e';
      await stop();
    }
    notifyListeners();
  }

  Future<void> restart() async {
    await stop();
    await start();
  }

  void _onEvent(BonsoirDiscoveryEvent event) {
    switch (event) {
      case BonsoirDiscoveryServiceFoundEvent():
        final discovery = _discovery;
        if (discovery != null) {
          unawaited(event.service.resolve(discovery.serviceResolver));
        }
      case BonsoirDiscoveryServiceResolvedEvent():
        _upsert(event.service);
      case BonsoirDiscoveryServiceUpdatedEvent():
        _upsert(event.service);
      case BonsoirDiscoveryServiceLostEvent():
        if (_hosts.remove(event.service.name) != null) notifyListeners();
      default:
        break;
    }
  }

  void _upsert(BonsoirService service) {
    final host = _pickAddress(service.hostAddresses) ?? service.hostname;
    if (host == null || host.isEmpty) return;
    final deviceId = service.attributes['id'];
    if (deviceId != null && deviceId == ownDeviceId) return;
    _hosts[service.name] = DiscoveredHost(
      serviceName: service.name,
      name: service.attributes['name'] ?? service.name,
      host: host,
      port: service.port,
      deviceId: deviceId,
    );
    notifyListeners();
  }

  /// 优先选择 IPv4 地址，便于直接拼接 URL。
  static String? _pickAddress(List<String> addresses) {
    final ipv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');
    for (final a in addresses) {
      if (ipv4.hasMatch(a)) return a;
    }
    return addresses.isEmpty ? null : addresses.first;
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    final discovery = _discovery;
    _discovery = null;
    if (discovery != null && !discovery.isStopped) {
      try {
        await discovery.stop();
      } catch (e) {
        debugPrint('停止设备发现失败：$e');
      }
    }
    _running = false;
  }

  @override
  void dispose() {
    unawaited(stop());
    super.dispose();
  }
}
