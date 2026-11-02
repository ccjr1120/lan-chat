import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/ui_strings.dart';
import '../theme.dart';
import '../theme_controller.dart';

/// 首页 / 聊天页右上角共享设置入口：主题与界面语言。
///
/// 选项通过 [AppPreferences] 写回 SettingsStore，立即生效并持久化。
class SettingsMenu extends StatelessWidget {
  const SettingsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferences.of(context);
    final l10n = context.l10n;
    String themeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => l10n.themeSystem,
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
    };
    IconData themeIcon(ThemeMode mode) => switch (mode) {
      ThemeMode.system => LucideIcons.monitor,
      ThemeMode.light => LucideIcons.sun,
      ThemeMode.dark => LucideIcons.moon,
    };
    // 语言名称使用各自语言书写，便于在不熟悉的界面语言下找到。
    final languages = <(Locale?, String)>[
      (null, l10n.languageSystem),
      (const Locale('zh'), '简体中文'),
      (const Locale('en'), 'English'),
    ];
    final currentLanguage = preferences.locale?.languageCode;

    PopupMenuEntry<VoidCallback> header(IconData icon, String text) =>
        PopupMenuItem<VoidCallback>(
          enabled: false,
          height: 36,
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.of(context).textSecondary),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
            ],
          ),
        );

    PopupMenuEntry<VoidCallback> option({
      required String label,
      required bool selected,
      required VoidCallback onSelected,
      IconData? icon,
    }) => PopupMenuItem<VoidCallback>(
      value: onSelected,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Semantics(
        selected: selected,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.of(context).selfBubble : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: icon == null
                    ? null
                    : Icon(
                        icon,
                        size: 18,
                        color: selected
                            ? AppColors.of(context).primary
                            : AppColors.of(context).textSecondary,
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.of(context).primary
                        : AppColors.of(context).textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  LucideIcons.check,
                  size: 18,
                  color: AppColors.of(context).primary,
                ),
            ],
          ),
        ),
      ),
    );

    return PopupMenuButton<VoidCallback>(
      position: PopupMenuPosition.under,
      tooltip: l10n.settings,
      icon: const Icon(LucideIcons.settings2, size: 21),
      onSelected: (apply) => apply(),
      itemBuilder: (context) => [
        header(LucideIcons.monitorSmartphone, l10n.deviceName),
        PopupMenuItem<VoidCallback>(
          enabled: false,
          height: 64,
          child: _DeviceNameField(
            initial: preferences.deviceName,
            hint: l10n.deviceNameHint,
            onSubmitted: (name) {
              preferences.onDeviceNameChanged(name);
              Navigator.pop(context);
            },
          ),
        ),
        const PopupMenuDivider(),
        header(LucideIcons.sunMoon, l10n.theme),
        for (final mode in ThemeMode.values)
          option(
            label: themeLabel(mode),
            icon: themeIcon(mode),
            selected: mode == preferences.themeMode,
            onSelected: () => preferences.onThemeChanged(mode),
          ),
        const PopupMenuDivider(),
        header(LucideIcons.languages, l10n.language),
        for (final (locale, label) in languages)
          option(
            label: label,
            selected: locale?.languageCode == currentLanguage,
            onSelected: () => preferences.onLocaleChanged(locale),
          ),
      ],
    );
  }
}

/// 设置菜单内联改名：回车保存，空名称不保存。
class _DeviceNameField extends StatefulWidget {
  const _DeviceNameField({
    required this.initial,
    required this.hint,
    required this.onSubmitted,
  });

  final String initial;
  final String hint;
  final ValueChanged<String> onSubmitted;

  @override
  State<_DeviceNameField> createState() => _DeviceNameFieldState();
}

class _DeviceNameFieldState extends State<_DeviceNameField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    maxLength: 32,
    maxLines: 1,
    textInputAction: TextInputAction.done,
    onSubmitted: widget.onSubmitted,
    decoration: InputDecoration(
      hintText: widget.hint,
      counterText: '',
      isDense: true,
    ),
  );
}
