import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/models/access_mode.dart';

/// 本机设置：设备 ID、设备名、主机访问模式、主题与界面语言。保存为 `settings.json`。
class SettingsStore extends ChangeNotifier {
  SettingsStore._(
    this._file,
    this._deviceId,
    this._deviceName,
    this._accessMode,
    this._themeMode,
    this._locale,
  );

  static const themeModes = ['system', 'light', 'dark'];

  /// 界面语言：system 跟随系统，其余为 AppLocalizations 支持的语言代码。
  static const locales = ['system', 'zh', 'en'];

  final File _file;
  final String _deviceId;
  String _deviceName;
  AccessMode _accessMode;
  String _themeMode;
  String _locale;

  String get deviceId => _deviceId;
  String get deviceName => _deviceName;
  AccessMode get accessMode => _accessMode;
  String get themeMode => _themeMode;
  String get locale => _locale;

  static Future<SettingsStore> load(File file) async {
    Map<String, dynamic> json = const {};
    if (await file.exists()) {
      try {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) json = decoded;
      } on FormatException {
        // 设置损坏时回退为默认值。
      }
    }
    final id = json['deviceId'] as String? ?? const Uuid().v4();
    final store = SettingsStore._(
      file,
      id,
      (json['deviceName'] as String?)?.trim().isNotEmpty == true
          ? json['deviceName'] as String
          : _defaultDeviceName(id),
      AccessMode.parse(json['accessMode']),
      themeModes.contains(json['themeMode'])
          ? json['themeMode'] as String
          : 'system',
      locales.contains(json['locale']) ? json['locale'] as String : 'system',
    );
    if (json.isEmpty) await store._save();
    return store;
  }

  Future<void> setDeviceName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _deviceName) return;
    _deviceName = trimmed.length > 32 ? trimmed.substring(0, 32) : trimmed;
    notifyListeners();
    await _save();
  }

  Future<void> setAccessMode(AccessMode mode) async {
    if (mode == _accessMode) return;
    _accessMode = mode;
    notifyListeners();
    await _save();
  }

  Future<void> setThemeMode(String mode) async {
    if (!themeModes.contains(mode) || mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _save();
  }

  Future<void> setLocale(String locale) async {
    if (!locales.contains(locale) || locale == _locale) return;
    _locale = locale;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(
      jsonEncode({
        'deviceId': _deviceId,
        'deviceName': _deviceName,
        'accessMode': _accessMode.name,
        'themeMode': _themeMode,
        'locale': _locale,
      }),
    );
  }

  static String _defaultDeviceName(String id) {
    final suffix = id.substring(0, 4).toUpperCase();
    if (Platform.isIOS) return 'iPhone-$suffix';
    if (Platform.isAndroid) return 'Android-$suffix';
    if (Platform.isMacOS) {
      final host = Platform.localHostname.split('.').first;
      return host.isNotEmpty ? host : 'Mac-$suffix';
    }
    return '设备-$suffix';
  }
}
