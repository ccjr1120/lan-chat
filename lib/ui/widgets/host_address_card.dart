import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/models/access_mode.dart';
import '../../l10n/ui_strings.dart';
import '../../server/host_session.dart';
import '../theme.dart';
import 'feature_icon.dart';

/// 连接信息面板内容：二维码、地址与加入确认开关。
class HostAddressCard extends StatelessWidget {
  const HostAddressCard({
    super.key,
    required this.session,
    this.compact = false,
  });
  final HostSession session;
  final bool compact;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final url = session.primaryUrl;
      final textTheme = Theme.of(context).textTheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (url != null) ...[
            if (compact)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _QrCode(url: url, size: 92),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.l10n.scanInstructions,
                          style: textTheme.bodySmall,
                        ),
                        _AddressRow(url: url),
                        for (final u in session.urls.skip(1))
                          _AddressRow(url: u),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  const FeatureIcon(icon: LucideIcons.qrCode, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.scanInstructions,
                      style: textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(child: _QrCode(url: url, size: 184)),
              const SizedBox(height: 20),
              for (final u in session.urls) _AddressRow(url: u),
            ],
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              context.l10n.requireApproval,
              style: const TextStyle(fontSize: 15),
            ),
            subtitle: Text(
              session.accessMode == AccessMode.open
                  ? context.l10n.directJoinDetail
                  : context.l10n.approvalDetail,
              style: textTheme.bodySmall,
            ),
            value: session.accessMode == AccessMode.approval,
            onChanged: (on) => session.setAccessMode(
              on ? AccessMode.approval : AccessMode.open,
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

class _QrCode extends StatelessWidget {
  const _QrCode({required this.url, required this.size});
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.of(context).divider),
    ),
    child: Semantics(
      label: context.l10n.qrDescription(url),
      child: QrImageView(data: url, size: size, padding: EdgeInsets.zero),
    ),
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
