import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/models/access_mode.dart';
import '../../l10n/ui_strings.dart';
import '../../server/host_session.dart';
import '../theme.dart';

/// 首页与会话详情共用的邀请面板。
class HostAddressCard extends StatelessWidget {
  const HostAddressCard({super.key, required this.session});
  final HostSession session;

  Future<void> _chooseAccessMode(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListenableBuilder(
          listenable: session,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.joinOptions,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final mode in AccessMode.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      mode == AccessMode.open
                          ? LucideIcons.lockOpen
                          : LucideIcons.shieldCheck,
                      color: AppColors.of(context).primary,
                    ),
                    title: Text(
                      mode == AccessMode.open
                          ? context.l10n.joinDirectly
                          : context.l10n.requireApproval,
                    ),
                    subtitle: Text(context.l10n.accessDescription(mode)),
                    trailing: session.accessMode == mode
                        ? Icon(
                            LucideIcons.check,
                            color: AppColors.of(context).primary,
                          )
                        : null,
                    onTap: () async {
                      await session.setAccessMode(mode);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final url = session.primaryUrl;
      final textTheme = Theme.of(context).textTheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.radio,
                size: 16,
                color: AppColors.of(context).success,
              ),
              SizedBox(width: 6),
              Text(
                context.l10n.sessionStarted,
                style: TextStyle(
                  color: AppColors.of(context).success,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.scanToJoin,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.scanInstructions,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          if (url != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.of(context).divider),
                ),
                child: Semantics(
                  label: context.l10n.qrDescription((url).toString()),
                  child: QrImageView(
                    data: url,
                    size: 184,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _AddressRow(url: url),
            if (session.urls.length > 1)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  context.l10n.otherAddresses,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.of(context).textSecondary,
                  ),
                ),
                children: [
                  for (final u in session.urls.skip(1)) _AddressRow(url: u),
                ],
              ),
          ] else
            const _NoNetworkHint(),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: session.refreshAddresses,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(context.l10n.refreshAddresses),
            ),
          ),
          const Divider(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              LucideIcons.shieldCheck,
              size: 22,
              color: AppColors.of(context).textSecondary,
            ),
            title: Text(
              context.l10n.accessMode,
              style: TextStyle(fontSize: 15),
            ),
            subtitle: Text(
              session.accessMode == AccessMode.open
                  ? context.l10n.directJoinDetail
                  : context.l10n.approvalDetail,
              style: textTheme.bodySmall,
            ),
            trailing: const Icon(LucideIcons.chevronRight, size: 18),
            onTap: () => _chooseAccessMode(context),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              session.accessMode == AccessMode.open
                  ? context.l10n.currentDirectJoin
                  : context.l10n.currentApproval,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.of(context).primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (session.statusMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              context.l10n.diagnostic(session.statusMessage!),
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.of(context).warning,
              ),
            ),
          ],
        ],
      );
    },
  );
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 3),
    padding: const EdgeInsets.only(left: 12, right: 4),
    decoration: BoxDecoration(
      color: AppColors.of(context).background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: SelectableText(
            url,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        IconButton(
          tooltip: context.l10n.copyAddress,
          icon: const Icon(LucideIcons.copy, size: 18),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.addressCopied)),
              );
            }
          },
        ),
      ],
    ),
  );
}

class _NoNetworkHint extends StatelessWidget {
  const _NoNetworkHint();
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(
          LucideIcons.wifiOff,
          size: 40,
          color: AppColors.of(context).textSecondary,
        ),
        SizedBox(height: 12),
        Text(context.l10n.noNetworkAddress),
        SizedBox(height: 4),
        Text(
          context.l10n.networkHint,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
      ],
    ),
  );
}
