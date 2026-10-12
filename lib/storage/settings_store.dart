import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/models/access_mode.dart';

/// 本机设置：设备 ID、设备名、主机访问模式。保存为 `settings.json`。
class SettingsStore extends ChangeNotifier {
  SettingsStore._(
    this._file,
    this._deviceId,
    this._deviceName,
    this._accessMode,
    this._themeMode,
  );

  final File _file;
  final String _deviceId;
  String _deviceName;
  AccessMode _accessMode;
  String _themeMode;

  String get deviceId => _deviceId;
  String get deviceName => _deviceName;
  AccessMode get accessMode => _accessMode;
  String get themeMode => _themeMode;

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
      const ['system', 'light', 'dark'].contains(json['themeMode'])
          ? json['themeMode'] as String
          : 'system',
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
    if (!const ['system', 'light', 'dark'].contains(mode) ||
        mode == _themeMode) {
      return;
    }
    _themeMode = mode;
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
