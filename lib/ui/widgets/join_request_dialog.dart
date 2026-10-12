import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/ui_strings.dart';
import '../../server/client_connection.dart';
import '../../server/host_session.dart';

/// 需确认模式下的加入请求弹窗。
///
/// 请求在弹窗期间失效（设备断开、主机切换为无需认证）时自动关闭。
/// 返回 true 表示同意、false 表示拒绝、null 表示请求已失效。
Future<bool?> showJoinRequestDialog(
  BuildContext context,
  HostSession session,
  JoinRequest request,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _JoinRequestDialog(session: session, request: request),
  );
}

class _JoinRequestDialog extends StatefulWidget {
  const _JoinRequestDialog({required this.session, required this.request});

  final HostSession session;
  final JoinRequest request;

  @override
  State<_JoinRequestDialog> createState() => _JoinRequestDialogState();
}

class _JoinRequestDialogState extends State<_JoinRequestDialog> {
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final stillPending = widget.session.pendingRequests.any(
      (r) => r.peer.id == widget.request.peer.id,
    );
    if (!stillPending && !_closed && mounted) {
      _closed = true;
      final route = ModalRoute.of(context);
      if (route != null && route.isActive) {
        Navigator.of(context).removeRoute(route);
      }
    }
  }

  void _finish(bool approve) {
    if (_closed) return;
    _closed = true;
    Navigator.of(context).pop(approve);
  }

  @override
  Widget build(BuildContext context) {
    final peer = widget.request.peer;
    return AlertDialog(
      icon: const Icon(LucideIcons.monitorSmartphone),
      title: Text(context.l10n.allowDevice),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(peer.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            context.l10n.peerType(context.l10n.platformLabel(peer.platform)),
          ),
          if (widget.request.remoteAddress.isNotEmpty)
            Text(
              context.l10n.peerAddress(
                (widget.request.remoteAddress).toString(),
              ),
            ),
          const SizedBox(height: 12),
          Text(context.l10n.joinPermissionDetail),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _finish(false),
          child: Text(context.l10n.reject),
        ),
        FilledButton(
          onPressed: () => _finish(true),
          child: Text(context.l10n.allowJoin),
        ),
      ],
    );
  }
}
