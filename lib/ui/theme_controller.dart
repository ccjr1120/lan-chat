import 'package:flutter/material.dart';

/// App-wide theme, language and device name selection. Persisted by SettingsStore in the
/// app root. [locale] is null when the interface follows the system language.
class AppPreferences extends InheritedWidget {
  const AppPreferences({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.locale,
    required this.onLocaleChanged,
    required this.deviceName,
    required this.onDeviceNameChanged,
    required super.child,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final Locale? locale;
  final ValueChanged<Locale?> onLocaleChanged;

  /// 本机显示名称；修改后在下次开启会话或加入会话时生效。
  final String deviceName;
  final ValueChanged<String> onDeviceNameChanged;

  static AppPreferences of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppPreferences>()!;

  @override
  bool updateShouldNotify(AppPreferences oldWidget) =>
      themeMode != oldWidget.themeMode ||
      locale != oldWidget.locale ||
      deviceName != oldWidget.deviceName;
}
