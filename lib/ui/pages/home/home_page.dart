import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../client/client_session.dart';
import '../../../discovery/lan_discovery.dart';
import '../../../l10n/ui_strings.dart';
import '../../../server/host_session.dart';
import '../../../storage/app_storage.dart';
import '../../theme.dart';
import '../../widgets/join_request_dialog.dart';
import '../../widgets/motion.dart';
import '../../widgets/settings_menu.dart';
import '../../widgets/workspace_panel.dart';
import '../chat/chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.storage});

  final AppStorage storage;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HostSession? _host;
  bool _starting = false;
  String? _hostError;
  final LanDiscovery _discovery = LanDiscovery();
  final TextEditingController _manualAddress = TextEditingController();
  bool _manualOpen = false;
  String? _manualError;
  String? _requestInDialog;

  @override
  void initState() {
    super.initState();
    _discovery.ownDeviceId = widget.storage.settings.deviceId;
    unawaited(_discovery.start());
  }

  @override
  void dispose() {
    _host?.removeListener(_onHostChanged);
    _host?.dispose();
    _discovery.dispose();
    _manualAddress.dispose();
    super.dispose();
  }

  /// 创建会话后直接进入聊天页；离开聊天页即结束会话。
  Future<void> _createSession() async {
    setState(() {
      _starting = true;
      _hostError = null;
    });
    HostSession? host;
    try {
      host = await HostSession.start(widget.storage);
    } catch (e) {
      if (mounted) setState(() => _hostError = e.toString());
    }
    if (!mounted) {
      host?.dispose();
      return;
    }
    setState(() => _starting = false);
    if (host == null) return;
    host.addListener(_onHostChanged);
    _host = host;
    unawaited(_discovery.stop());
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(session: host!, ownsSession: false),
      ),
    );
    await _stopHost();
    if (mounted) unawaited(_discovery.start());
  }

  Future<void> _stopHost() async {
    final host = _host;
    if (host == null) return;
    _host = null;
    host.removeListener(_onHostChanged);
    await host.close();
    host.dispose();
  }

  void _onHostChanged() => unawaited(_maybeShowJoinRequest());

  Future<void> _maybeShowJoinRequest() async {
    final host = _host;
    if (host == null || _requestInDialog != null || !mounted) return;
    final requests = host.pendingRequests;
    if (requests.isEmpty) return;
    final request = requests.first;
    _requestInDialog = request.peer.id;
    final approved = await showJoinRequestDialog(context, host, request);
    _requestInDialog = null;
    if (approved == true) {
      host.approve(request.peer.id);
    } else if (approved == false) {
      host.reject(request.peer.id);
    }
    if (mounted) unawaited(_maybeShowJoinRequest());
  }

  Future<void> _connect(String host, int port, {String? name}) async {
    final session = ClientSession(
      storage: widget.storage,
      host: host,
      port: port,
      hostName: name,
    );
    unawaited(session.connect());
    unawaited(_discovery.stop());
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(session: session, ownsSession: true),
      ),
    );
    if (mounted) unawaited(_discovery.start());
  }

  static (String, int)? _parseAddress(String input) {
    var text = input.trim();
    if (text.isEmpty) return null;
    if (!text.contains('://')) text = 'http://$text';
    final uri = Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty) return null;
    final port = uri.hasPort ? uri.port : 8686;
    if (port <= 0 || port > 65535) return null;
    return (uri.host, port);
  }

  void _submitManual() {
    final parsed = _parseAddress(_manualAddress.text);
    if (parsed == null) {
      setState(() => _manualError = context.l10n.invalidAddress);
      return;
    }
    setState(() => _manualError = null);
    unawaited(_connect(parsed.$1, parsed.$2));
  }

  @override
  Widget build(BuildContext context) {
    final macOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      // macOS has a native title bar at every window width.
      appBar: macOS
          ? null
          : AppBar(
              title: Text(context.l10n.appName),
              actions: const [SettingsMenu(), SizedBox(width: 8)],
            ),
      body: WorkspaceBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 40 : 20,
                  vertical: wide ? 28 : 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FadeSlideIn(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.l10n.homeHeadline,
                                  style: textTheme.headlineMedium,
                                ),
                              ),
                              if (macOS) const SettingsMenu(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 40),
                          child: Text(
                            '${context.l10n.currentDevice} · '
                            '${widget.storage.settings.deviceName}',
                            style: textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 60),
                          child: _createCard(),
                        ),
                        const SizedBox(height: 28),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 80),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      context.l10n.nearbySessions,
                                      style: textTheme.titleMedium,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: context.l10n.searchAgain,
                                    icon: const Icon(
                                      LucideIcons.refreshCw,
                                      size: 20,
                                    ),
                                    onPressed: _discovery.restart,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 160,
                                ),
                                child: ListenableBuilder(
                                  listenable: _discovery,
                                  builder: (context, _) => _nearbySessions(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _manualAddressEntry(colors),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _createCard() {
    final colors = AppColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.createSessionDetail,
              style: TextStyle(color: colors.textSecondary),
            ),
            if (_hostError != null) ...[
              const SizedBox(height: 12),
              Text(
                context.l10n.startFailed(context.l10n.diagnostic(_hostError!)),
                style: TextStyle(color: colors.danger),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _starting ? null : _createSession,
              icon: _starting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.plus, size: 20),
              label: Text(
                _starting
                    ? context.l10n.creatingSession
                    : context.l10n.createSession,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _manualAddressEntry(AppColors colors) {
    if (!_manualOpen) {
      return Align(
        child: TextButton.icon(
          onPressed: () => setState(() => _manualOpen = true),
          icon: const Icon(LucideIcons.link, size: 18),
          label: Text(context.l10n.enterAddress),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextField(
        controller: _manualAddress,
        autofocus: true,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.go,
        onSubmitted: (_) => _submitManual(),
        onChanged: (_) {
          if (_manualError != null) setState(() => _manualError = null);
        },
        decoration: InputDecoration(
          hintText: '192.168.1.8:8686',
          labelText: context.l10n.sessionAddress,
          helperText: context.l10n.manualAddressHint,
          errorText: _manualError,
          suffixIcon: IconButton(
            tooltip: context.l10n.connectDevice,
            icon: const Icon(LucideIcons.arrowRight, size: 20),
            onPressed: _submitManual,
          ),
        ),
      ),
    );
  }

  Widget _nearbySessions() {
    final colors = AppColors.of(context);
    final hosts = _discovery.hosts;
    final error = _discovery.error;
    final Widget content;
    if (hosts.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _FeatureIcon(icon: LucideIcons.radar, large: true),
              const SizedBox(height: 16),
              Text(
                error == null
                    ? context.l10n.searchingDevices
                    : context.l10n.discoveryFailed,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                error == null
                    ? context.l10n.nearbyHint
                    : context.l10n.diagnostic(error),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (error == null) ...[
                const SizedBox(height: 20),
                const SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              ],
            ],
          ),
        ),
      );
    } else {
      final tiles = [
        for (final h in hosts)
          ListTile(
            enabled: !_starting,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const _FeatureIcon(icon: LucideIcons.smartphone),
            title: Text(
              h.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(h.address),
            trailing: const Icon(LucideIcons.arrowRight, size: 20),
            onTap: () => _connect(h.host, h.port, name: h.name),
          ),
      ];
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              tiles[i],
            ],
          ],
        ),
      );
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.divider),
      ),
      child: AnimatedSwitcher(
        duration: AppMotion.durationOf(context),
        switchInCurve: AppMotion.curve,
        switchOutCurve: AppMotion.curve,
        child: KeyedSubtree(
          key: ValueKey((hosts.isEmpty, error != null)),
          child: content,
        ),
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon({required this.icon, this.large = false});
  final IconData icon;
  final bool large;

  @override
  Widget build(BuildContext context) => Container(
    width: large ? 56 : 44,
    height: large ? 56 : 44,
    decoration: BoxDecoration(
      color: AppColors.of(context).selfBubble,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(
      icon,
      size: large ? 28 : 22,
      color: AppColors.of(context).primary,
    ),
  );
}
