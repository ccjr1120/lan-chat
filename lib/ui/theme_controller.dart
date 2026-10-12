import 'package:flutter/material.dart';

/// App-wide theme selection. Persisted by SettingsStore in the app root.
class AppPreferences extends InheritedWidget {
  const AppPreferences({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required super.child,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  static AppPreferences of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppPreferences>()!;

  @override
  bool updateShouldNotify(AppPreferences oldWidget) =>
      themeMode != oldWidget.themeMode;
}
