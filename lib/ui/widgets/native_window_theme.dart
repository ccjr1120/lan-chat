import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/ui_strings.dart';

/// Synchronize the native macOS title and appearance with MaterialApp.
class NativeWindowTheme extends StatefulWidget {
  const NativeWindowTheme({
    super.key,
    required this.themeMode,
    required this.child,
  });
  final ThemeMode themeMode;
  final Widget child;

  @override
  State<NativeWindowTheme> createState() => _NativeWindowThemeState();
}

class _NativeWindowThemeState extends State<NativeWindowTheme> {
  static const _channel = MethodChannel('lanchat/window');
  String? _lastStyle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(NativeWindowTheme oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) return;
    final title = context.l10n.appName;
    final mode = widget.themeMode.name;
    final brightness = Theme.of(context).brightness.name;
    final style = '$title/$mode/$brightness';
    if (_lastStyle == style) return;
    _lastStyle = style;
    unawaited(_apply(title, mode));
  }

  Future<void> _apply(String title, String mode) async {
    try {
      await _channel.invokeMethod<void>('setStyle', {
        'title': title,
        'theme': mode,
      });
    } on MissingPluginException {
      debugPrint(
        'Restart the macOS app to enable native window theme changes.',
      );
    } on PlatformException catch (error) {
      debugPrint('Unable to update the native window: ${error.message}');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
