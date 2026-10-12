/// 全局常量。网页端 `assets/web/index.html` 中的协议常量需与此保持一致。
abstract final class LanChatConstants {
  /// mDNS 服务类型，iOS/macOS 的 `NSBonjourServices` 需声明同名条目。
  static const String serviceType = '_lanchat._tcp';

  /// 主机优先监听的端口，被占用时回退为系统分配端口。
  static const int preferredPort = 8686;

  /// 协议版本，写入 mDNS TXT 记录与 `/api/info`。
  static const String protocolVersion = '1';

  /// 握手（hello）超时时间，超时未握手的连接会被关闭。
  static const Duration helloTimeout = Duration(seconds: 10);

  /// WebSocket 心跳间隔。
  static const Duration pingInterval = Duration(seconds: 20);

  /// 新连接通过 `history` 事件获得的最大历史条数。
  static const int historyLimit = 500;
}
