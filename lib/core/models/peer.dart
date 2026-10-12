/// 会话参与方的终端类型。
enum PeerPlatform {
  /// 开启服务端的主机 App。
  host,

  /// 以客户端模式接入的 App。
  app,

  /// 通过浏览器接入的网页端。
  web;

  static PeerPlatform parse(Object? value) => PeerPlatform.values.firstWhere(
        (p) => p.name == value,
        orElse: () => PeerPlatform.web,
      );

  String get label => switch (this) {
        PeerPlatform.host => '主机',
        PeerPlatform.app => 'App',
        PeerPlatform.web => '网页',
      };
}

/// 会话中的一个设备。同一 [id]（设备 ID）的多个连接只算一个参与方。
class Peer {
  const Peer({required this.id, required this.name, required this.platform});

  final String id;
  final String name;
  final PeerPlatform platform;

  factory Peer.fromJson(Map<String, dynamic> json) => Peer(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '未命名设备',
        platform: PeerPlatform.parse(json['platform']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'platform': platform.name,
      };
}
