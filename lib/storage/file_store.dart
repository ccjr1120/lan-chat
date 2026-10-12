import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/models/chat_message.dart';

/// 传输文件的本地存储：`<Documents>/files/<fileId>/<fileName>`。
///
/// 主机保存所有收到/发出的文件；客户端 App 保存已下载的文件。
/// iOS 开启了 `UIFileSharingEnabled`，可在“文件”App 中看到该目录。
class FileStore {
  FileStore(this.rootDir);

  final Directory rootDir;

  Directory dirFor(String fileId) =>
      Directory(p.join(rootDir.path, sanitizeId(fileId)));

  File fileFor(FileMeta meta) =>
      File(p.join(dirFor(meta.id).path, sanitizeFileName(meta.name)));

  Future<bool> exists(FileMeta meta) => fileFor(meta).exists();

  /// 写入中的临时文件，完成后通过 [commit] 改名为正式文件。
  Future<File> createPartFile(String fileId) async {
    final dir = dirFor(fileId);
    await dir.create(recursive: true);
    return File(p.join(dir.path, '.part'));
  }

  Future<File> commit(File part, FileMeta meta) async {
    final target = fileFor(meta);
    if (await target.exists()) await target.delete();
    return part.rename(target.path);
  }

  /// 将本地文件流复制进存储（主机自己发送文件时使用），[onProgress] 回调已写入字节数。
  Future<File> importStream(
    FileMeta meta,
    Stream<List<int>> source, {
    void Function(int written)? onProgress,
  }) async {
    final part = await createPartFile(meta.id);
    final sink = part.openWrite();
    var written = 0;
    try {
      await for (final chunk in source) {
        sink.add(chunk);
        written += chunk.length;
        onProgress?.call(written);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    return commit(part, meta);
  }

  /// 文件 ID 只允许字母数字与连字符，防止路径穿越。
  static String sanitizeId(String id) {
    final cleaned = id.replaceAll(RegExp(r'[^A-Za-z0-9\-]'), '');
    return cleaned.isEmpty ? 'invalid' : cleaned;
  }

  /// 去除路径分隔符、控制字符，限制长度，保留扩展名。
  static String sanitizeFileName(String name) {
    var base = p.basename(name.replaceAll('\\', '/'));
    base = base.replaceAll(RegExp(r'[\x00-\x1F\x7F/:*?"<>|]'), '_').trim();
    if (base.isEmpty || base == '.' || base == '..' || base == '.part') {
      base = 'file';
    }
    if (base.length > 120) {
      final ext = p.extension(base);
      final keep = ext.length < 20 ? ext : '';
      base = base.substring(0, 120 - keep.length) + keep;
    }
    return base;
  }
}
