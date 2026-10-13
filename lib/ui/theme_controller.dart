import 'package:flutter/material.dart';

/// App-wide theme and language selection. Persisted by SettingsStore in the
/// app root. [locale] is null when the interface follows the system language.
class AppPreferences extends InheritedWidget {
  const AppPreferences({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.locale,
    required this.onLocaleChanged,
    required super.child,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final Locale? locale;
  final ValueChanged<Locale?> onLocaleChanged;

  static AppPreferences of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppPreferences>()!;

  @override
  bool updateShouldNotify(AppPreferences oldWidget) =>
      themeMode != oldWidget.themeMode || locale != oldWidget.locale;
}
