import 'dart:convert';

/// WebSocket `/ws` 上的事件类型。帧格式统一为 `{"type": "...", "data": ...}`。
///
/// 客户端 → 主机：[hello]、[message]。
/// 主机 → 客户端：[pending]、[welcome]、[rejected]、[peers]、[history]、
/// [message]、[error]。
abstract final class WsEventType {
  /// 握手：`{deviceId, name, platform}`。连接后必须首先发送。
  static const String hello = 'hello';

  /// 需确认模式下，主机尚未同意，客户端应显示“等待主机确认”。
  static const String pending = 'pending';

  /// 已加入会话：`{self, host, token, accessMode}`。
  /// `token` 用于后续 HTTP 接口（上传/下载/历史）鉴权。
  static const String welcome = 'welcome';

  /// 主机拒绝加入：`{reason}`，随后主机关闭连接。
  static const String rejected = 'rejected';

  /// 在线设备列表：`[Peer]`（含主机自身）。
  static const String peers = 'peers';

  /// 历史消息：`[ChatMessage]`，按时间升序。
  static const String history = 'history';

  /// 客户端发送时为 `{text}`；主机广播时为完整 `ChatMessage`。
  static const String message = 'message';

  /// 错误提示：`{message}`。
  static const String error = 'error';
}

/// 一条 WebSocket 事件。
class WsEvent {
  const WsEvent(this.type, [this.data]);

  final String type;
  final Object? data;

  /// 解析一帧文本，格式不合法时返回 null。
  static WsEvent? tryDecode(Object? frame) {
    if (frame is! String) return null;
    try {
      final json = jsonDecode(frame);
      if (json is! Map<String, dynamic>) return null;
      final type = json['type'];
      if (type is! String) return null;
      return WsEvent(type, json['data']);
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic> get dataMap =>
      data is Map<String, dynamic> ? data as Map<String, dynamic> : const {};

  List<Map<String, dynamic>> get dataList => data is List
      ? (data as List).whereType<Map<String, dynamic>>().toList()
      : const [];

  String encode() => jsonEncode({'type': type, 'data': data});
}
