import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/ui_strings.dart';
import 'storage/app_storage.dart';
import 'ui/pages/home/home_page.dart';
import 'ui/theme.dart';
import 'ui/theme_controller.dart';
import 'ui/widgets/native_window_theme.dart';

class LanChatApp extends StatelessWidget {
  const LanChatApp({super.key, required this.storage});

  final AppStorage storage;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: storage.settings,
    builder: (context, _) {
      final mode = ThemeMode.values.byName(storage.settings.themeMode);
      return AppPreferences(
        themeMode: mode,
        onThemeChanged: (value) =>
            unawaited(storage.settings.setThemeMode(value.name)),
        child: MaterialApp(
          onGenerateTitle: (context) => context.l10n.appName,
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          darkTheme: buildAppTheme(brightness: Brightness.dark),
          themeMode: mode,
          themeAnimationDuration: const Duration(milliseconds: 250),
          themeAnimationCurve: Curves.easeInOut,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              NativeWindowTheme(themeMode: mode, child: child!),
          home: HomePage(storage: storage),
        ),
      );
    },
  );
}
