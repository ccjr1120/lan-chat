import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../models/peer.dart';

/// 会话连接状态。主机会话启动后始终为 [connected]。
enum SessionStatus {
  /// 正在连接主机。
  connecting,

  /// 已连接，等待主机确认（需确认模式）。
  pending,

  /// 已加入会话。
  connected,

  /// 主机拒绝加入，终止状态，不会自动重连。
  rejected,

  /// 连接断开（会自动重连）。
  disconnected,

  /// 用户主动结束会话。
  closed,
}

/// 发送中的文件，在聊天列表底部显示为临时气泡。
class OutgoingTransfer {
  OutgoingTransfer({required this.id, required this.name, required this.size});

  final String id;
  final String name;
  final int size;
  int sent = 0;
  String? error;

  double get progress => size <= 0 ? 0 : (sent / size).clamp(0, 1).toDouble();

  int _lastNotifiedPercent = -1;

  /// 更新已发送字节数；进度每变化 1% 才返回 true，用于节流界面刷新。
  bool update(int sentBytes) {
    sent = sentBytes;
    final percent = (progress * 100).floor();
    if (percent == _lastNotifiedPercent) return false;
    _lastNotifiedPercent = percent;
    return true;
  }
}

/// 待发送的本地文件（来源于文件选择器）。
class LocalFileSource {
  const LocalFileSource({
    required this.name,
    required this.size,
    required this.openRead,
  });

  final String name;
  final int size;

  /// 每次调用返回一个新的字节流（上传失败重试时需要重新读取）。
  final Stream<List<int>> Function() openRead;
}

/// UI 使用的统一会话接口：主机会话（server/）与客户端会话（client/）各自实现。
abstract class ChatSession extends ChangeNotifier {
  bool _disposed = false;

  /// 会话在 [dispose] 后仍可能有异步收尾（关闭连接/服务），此时不再通知监听者。
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  /// 子类应在调用 super 前触发 [close]。
  @override
  @mustCallSuper
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// 当前设备在会话中的身份。
  Peer get self;

  /// 会话标题（主机设备名）。
  String get title;

  bool get isHost;

  SessionStatus get status;

  /// 状态补充说明，例如拒绝原因或断开原因。
  String? get statusMessage;

  /// 按时间升序的消息列表。
  List<ChatMessage> get messages;

  /// 在线设备（含主机）。
  List<Peer> get peers;

  /// 发送中的文件。
  List<OutgoingTransfer> get outgoing;

  /// 文件下载进度（0~1），键为文件 ID。
  Map<String, double> get downloads;

  Future<void> sendText(String text);

  Future<void> sendFile(LocalFileSource file);

  /// 文件已在本地时返回路径，否则返回 null。
  Future<String?> localPathFor(FileMeta file);

  /// 确保文件已保存到本地并返回路径（客户端会按需下载）。
  Future<String> ensureLocal(FileMeta file);

  /// 结束会话：主机停止服务，客户端断开连接。
  Future<void> close();
}
