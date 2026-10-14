import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/ui_strings.dart';
import '../theme.dart';

class WorkspaceBackground extends StatelessWidget {
  const WorkspaceBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.4,
            colors: [colors.glow, colors.background],
          ),
        ),
        child: child,
      ),
    );
  }
}

class ConnectionDiagram extends StatelessWidget {
  const ConnectionDiagram({super.key, required this.deviceName});
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final desktop = switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => true,
      _ => false,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        return Container(
          padding: EdgeInsets.all(compact ? 16 : 24),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DiagramDevice(
                      icon: desktop
                          ? LucideIcons.monitor
                          : LucideIcons.smartphone,
                      title: deviceName,
                      subtitle: context.l10n.currentDevice,
                      primary: true,
                      compact: compact,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16),
                    child: Icon(
                      LucideIcons.arrowLeftRight,
                      size: compact ? 20 : 24,
                      color: colors.primary,
                    ),
                  ),
                  Expanded(
                    child: _DiagramDevice(
                      icon: LucideIcons.smartphone,
                      title: context.l10n.phoneBrowser,
                      subtitle: context.l10n.connectionDiagram,
                      compact: compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.radio, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      context.l10n.sameNetworkNoAccount,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DiagramDevice extends StatelessWidget {
  const _DiagramDevice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.compact,
    this.primary = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        Container(
          width: compact ? 56 : 72,
          height: compact ? 56 : 72,
          decoration: BoxDecoration(
            color: primary ? colors.selfBubble : colors.surface,
            borderRadius: BorderRadius.circular(compact ? 16 : 20),
          ),
          child: Icon(
            icon,
            size: compact ? 28 : 34,
            color: primary ? colors.primary : colors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Tooltip(
          message: title,
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
      ],
    );
  }
}
