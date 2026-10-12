import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/models/peer.dart';
import '../core/protocol/ws_event.dart';

/// 单条 WebSocket 连接在主机侧的状态。
enum ConnectionState {
  /// 已建立连接，尚未发送 hello。
  handshaking,

  /// 已发送 hello，等待主机确认（需确认模式）。
  pending,

  /// 已加入会话，可以收发消息。
  joined,
}

/// 主机持有的一条客户端连接。
class ClientConnection {
  ClientConnection({
    required this.id,
    required this.channel,
    required this.remoteAddress,
  });

  /// 连接 ID（每次连接唯一，区别于设备 ID）。
  final String id;
  final WebSocketChannel channel;
  final String remoteAddress;

  ConnectionState state = ConnectionState.handshaking;
  Peer? peer;
  Timer? helloTimer;

  bool get isJoined => state == ConnectionState.joined;

  void send(WsEvent event) {
    try {
      channel.sink.add(event.encode());
    } catch (_) {
      // 连接已关闭时忽略，清理由 onDone 负责。
    }
  }

  Future<void> close([int? code, String? reason]) async {
    helloTimer?.cancel();
    try {
      await channel.sink.close(code, reason);
    } catch (_) {
      // 忽略重复关闭。
    }
  }
}

/// 需确认模式下待主机处理的加入请求。
class JoinRequest {
  JoinRequest({
    required this.connectionId,
    required this.peer,
    required this.remoteAddress,
  }) : requestedAt = DateTime.now();

  final String connectionId;
  final Peer peer;
  final String remoteAddress;
  final DateTime requestedAt;
}
