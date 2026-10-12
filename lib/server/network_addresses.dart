import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';

/// 获取本机可供局域网访问的 IPv4 地址。
///
/// Wi-Fi 地址优先；开启热点时设备本身是网关，`getWifiIP` 可能为空，
/// 因此补充枚举所有网卡上的私有地址（热点网段通常为 192.168.43.x / 172.20.10.x）。
Future<List<String>> lanIPv4Addresses() async {
  final result = <String>[];
  try {
    final wifi = await NetworkInfo().getWifiIP();
    if (wifi != null && _isUsable(wifi)) result.add(wifi);
  } catch (_) {
    // 部分平台或权限不足时会抛出，忽略后走网卡枚举。
  }
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    final candidates = <String>[];
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (_isUsable(addr.address) && !result.contains(addr.address)) {
          candidates.add(addr.address);
        }
      }
    }
    candidates.sort((a, b) => _rank(a).compareTo(_rank(b)));
    result.addAll(candidates);
  } catch (_) {
    // 忽略，返回已获取的部分。
  }
  return result;
}

bool _isUsable(String ip) =>
    !ip.startsWith('127.') && !ip.startsWith('169.254.') && ip != '0.0.0.0';

/// 常见家用/热点私有网段优先，其余（如运营商蜂窝地址）靠后。
int _rank(String ip) {
  if (ip.startsWith('192.168.')) return 0;
  if (ip.startsWith('10.')) return 1;
  final parts = ip.split('.');
  if (parts.length == 4 && parts[0] == '172') {
    final second = int.tryParse(parts[1]) ?? 0;
    if (second >= 16 && second <= 31) return 1;
  }
  return 2;
}
