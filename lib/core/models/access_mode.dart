/// 主机的访问控制模式，可在运行中随时切换。
enum AccessMode {
  /// 无需认证：局域网内任何设备直接加入会话。
  open,

  /// 需确认：新设备加入时由主机同意后才进入会话。
  approval;

  static AccessMode parse(Object? value) =>
      value == 'approval' ? AccessMode.approval : AccessMode.open;

  String get label => switch (this) {
        AccessMode.open => '无需认证',
        AccessMode.approval => '需确认',
      };

  String get description => switch (this) {
        AccessMode.open => '局域网内任何设备可直接加入',
        AccessMode.approval => '新设备加入前需要你在本机同意',
      };
}
