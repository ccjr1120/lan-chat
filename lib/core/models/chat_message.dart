import 'peer.dart';

enum MessageKind {
  text,
  file;

  static MessageKind parse(Object? value) =>
      value == 'file' ? MessageKind.file : MessageKind.text;
}

/// 文件消息携带的元数据。实际文件由主机保存在 `files/<id>/<name>`。
class FileMeta {
  const FileMeta({
    required this.id,
    required this.name,
    required this.size,
    required this.mime,
  });

  final String id;
  final String name;
  final int size;
  final String mime;

  bool get isImage => mime.startsWith('image/');

  factory FileMeta.fromJson(Map<String, dynamic> json) => FileMeta(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'file',
        size: (json['size'] as num?)?.toInt() ?? 0,
        mime: json['mime'] as String? ?? 'application/octet-stream',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'size': size,
        'mime': mime,
      };
}

/// 一条聊天记录。由主机统一分配 [id] 与 [timestamp]。
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.kind,
    required this.sender,
    required this.timestamp,
    this.text,
    this.file,
  });

  final String id;
  final MessageKind kind;
  final Peer sender;

  /// 毫秒时间戳。
  final int timestamp;
  final String? text;
  final FileMeta? file;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final file = json['file'];
    final sender = json['sender'];
    return ChatMessage(
      id: json['id'] as String? ?? '',
      kind: MessageKind.parse(json['kind']),
      sender: sender is Map<String, dynamic>
          ? Peer.fromJson(sender)
          : const Peer(id: '', name: '未知', platform: PeerPlatform.web),
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      text: json['text'] as String?,
      file: file is Map<String, dynamic> ? FileMeta.fromJson(file) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'sender': sender.toJson(),
        'timestamp': timestamp,
        if (text != null) 'text': text,
        if (file != null) 'file': file!.toJson(),
      };
}
