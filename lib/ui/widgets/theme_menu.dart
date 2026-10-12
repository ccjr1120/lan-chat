import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/ui_strings.dart';
import '../theme_controller.dart';

class ThemeMenu extends StatelessWidget {
  const ThemeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferences.of(context);
    String label(ThemeMode mode) => switch (mode) {
      ThemeMode.system => context.l10n.themeSystem,
      ThemeMode.light => context.l10n.themeLight,
      ThemeMode.dark => context.l10n.themeDark,
    };
    IconData icon(ThemeMode mode) => switch (mode) {
      ThemeMode.system => LucideIcons.monitor,
      ThemeMode.light => LucideIcons.sun,
      ThemeMode.dark => LucideIcons.moon,
    };
    return PopupMenuButton<ThemeMode>(
      tooltip: '${context.l10n.theme}: ${label(preferences.themeMode)}',
      initialValue: preferences.themeMode,
      icon: Icon(icon(preferences.themeMode), size: 21),
      onSelected: preferences.onThemeChanged,
      itemBuilder: (context) => [
        for (final mode in ThemeMode.values)
          PopupMenuItem(
            value: mode,
            child: Row(
              children: [
                Icon(icon(mode), size: 18),
                const SizedBox(width: 12),
                Expanded(child: Text(label(mode))),
                if (mode == preferences.themeMode)
                  const Icon(LucideIcons.check, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}
