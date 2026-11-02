import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../core/models/chat_message.dart';

/// 主机聊天记录：JSON Lines 格式，每行一条 [ChatMessage]，只追加写入。
class HistoryStore {
  HistoryStore(this.file);

  final File file;

  /// 串行化写入，避免并发追加交错。
  Future<void> _queue = Future.value();

  Future<List<ChatMessage>> load({int? limit}) async {
    if (!await file.exists()) return [];
    final lines = await file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final selected = limit != null && lines.length > limit
        ? lines.sublist(lines.length - limit)
        : lines;
    final messages = <ChatMessage>[];
    for (final line in selected) {
      try {
        final json = jsonDecode(line);
        if (json is Map<String, dynamic>) {
          messages.add(ChatMessage.fromJson(json));
        }
      } on FormatException {
        // 跳过损坏的行（例如异常退出时写了一半）。
      }
    }
    return messages;
  }

  Future<void> append(ChatMessage message) {
    final line = '${jsonEncode(message.toJson())}\n';
    _queue = _queue.then(
      (_) => file.writeAsString(line, mode: FileMode.append, flush: true),
    );
    return _queue;
  }

  /// 为新会话归档旧记录，文件本身仍保留在原来的文件目录。
  Future<void> archive() {
    _queue = _queue.then((_) async {
      if (!await file.exists()) return;
      final archiveDir = Directory('${file.parent.path}/history_archive');
      await archiveDir.create(recursive: true);
      await file.rename('${archiveDir.path}/${const Uuid().v4()}.jsonl');
    });
    return _queue;
  }

  Future<void> clear() {
    _queue = _queue.then((_) async {
      if (await file.exists()) await file.delete();
    });
    return _queue;
  }
}
