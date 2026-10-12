import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'file_store.dart';
import 'history_store.dart';
import 'settings_store.dart';

/// 存储模块入口，应用启动时打开一次。
///
/// - 设置与聊天记录放在 ApplicationSupport 目录（用户不可见）；
/// - 传输文件放在 Documents/files（iOS 可在“文件”App 中查看）。
class AppStorage {
  AppStorage._(this.settings, this.history, this.files);

  final SettingsStore settings;
  final HistoryStore history;
  final FileStore files;

  static Future<AppStorage> open() async {
    final support = await getApplicationSupportDirectory();
    final docs = await getApplicationDocumentsDirectory();
    await support.create(recursive: true);
    final filesDir = Directory(p.join(docs.path, 'files'));
    await filesDir.create(recursive: true);
    return AppStorage._(
      await SettingsStore.load(File(p.join(support.path, 'settings.json'))),
      HistoryStore(File(p.join(support.path, 'history.jsonl'))),
      FileStore(filesDir),
    );
  }
}
