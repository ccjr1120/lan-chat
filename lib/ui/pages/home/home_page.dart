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
import '../../widgets/host_address_card.dart';
import '../../widgets/join_request_dialog.dart';
import '../../widgets/motion.dart';
import '../../widgets/settings_menu.dart';
import '../../widgets/workspace_panel.dart';
import '../chat/chat_page.dart';

enum _View { home, hosting, joining }

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.storage});

  final AppStorage storage;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HostSession? _host;
  bool _joining = false;
  bool _starting = false;
  String? _hostError;
  final LanDiscovery _discovery = LanDiscovery();
  final TextEditingController _manualAddress = TextEditingController();
  String? _requestInDialog;

  @override
  void initState() {
    super.initState();
    _discovery.ownDeviceId = widget.storage.settings.deviceId;
  }

  @override
  void dispose() {
    _host?.removeListener(_onHostChanged);
    _host?.dispose();
    _discovery.dispose();
    _manualAddress.dispose();
    super.dispose();
  }

  Future<void> _startHost() async {
    setState(() {
      _starting = true;
      _hostError = null;
    });
    try {
      final host = await HostSession.start(widget.storage);
      host.addListener(_onHostChanged);
      if (!mounted) {
        host.dispose();
        return;
      }
      setState(() => _host = host);
    } catch (e) {
      if (mounted) setState(() => _hostError = e.toString());
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _stopHost() async {
    final host = _host;
    if (host == null) return;
    host.removeListener(_onHostChanged);
    setState(() => _host = null);
    await host.close();
    host.dispose();
  }

  void _onHostChanged() => unawaited(_maybeShowJoinRequest());

  Future<void> _confirmStopHost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.endSessionTitle),
        content: Text(context.l10n.endSessionDetail),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.continueSession),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.of(context).danger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.endSession),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _stopHost();
  }

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

  Future<void> _openHostChat() async {
    final host = _host;
    if (host == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(session: host, ownsSession: false),
      ),
    );
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
    if (mounted && _joining) unawaited(_discovery.start());
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

  _View get _view => _host != null
      ? _View.hosting
      : _joining
      ? _View.joining
      : _View.home;

  void _setJoining(bool joining) {
    if (joining == _joining) return;
    setState(() => _joining = joining);
    unawaited(joining ? _discovery.start() : _discovery.stop());
  }

  void _goBack() {
    switch (_view) {
      case _View.joining:
        _setJoining(false);
      case _View.hosting:
        unawaited(_confirmStopHost());
      case _View.home:
        break;
    }
  }

  Future<void> _editDeviceName() async {
    final settings = widget.storage.settings;
    final controller = TextEditingController(text: settings.deviceName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deviceName),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 32,
          decoration: InputDecoration(hintText: context.l10n.deviceNameHint),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) {
      await settings.setDeviceName(name);
      if (mounted) setState(() {});
    }
  }

  Key _stageKey(String slot) => ValueKey((slot, _view));

  @override
  Widget build(BuildContext context) {
    final view = _view;
    final canGoBack = view != _View.home;
    final macOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    final (headline, detail) = switch (view) {
      _View.home => (context.l10n.homeHeadline, context.l10n.homeDetail),
      _View.hosting => (context.l10n.sessionReady, context.l10n.inviteDetail),
      _View.joining => (
        context.l10n.joinSession,
        context.l10n.findDevicesDetail,
      ),
    };
    final backButton = IconButton(
      tooltip: context.l10n.backHome,
      icon: const Icon(LucideIcons.arrowLeft),
      onPressed: _goBack,
    );
    return PopScope(
      canPop: !canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        // macOS has a native title bar at every window width.
        appBar: macOS
            ? null
            : AppBar(
                leading: canGoBack ? backButton : null,
                title: Text(switch (view) {
                  _View.home => context.l10n.appName,
                  _View.hosting => context.l10n.sessionStarted,
                  _View.joining => context.l10n.joinSession,
                }),
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
                            key: _stageKey('title'),
                            child: Row(
                              children: [
                                if (macOS && canGoBack) ...[
                                  backButton,
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Text(
                                    headline,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                ),
                                if (macOS) const SettingsMenu(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          FadeSlideIn(
                            key: _stageKey('detail'),
                            delay: const Duration(milliseconds: 40),
                            child: Text(
                              detail,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          if (view == _View.home) ...[
                            const SizedBox(height: 16),
                            FadeSlideIn(
                              key: _stageKey('device'),
                              delay: const Duration(milliseconds: 40),
                              child: _deviceChip(),
                            ),
                          ],
                          const SizedBox(height: 28),
                          FadeSlideIn(
                            key: _stageKey('body'),
                            delay: const Duration(milliseconds: 60),
                            child: switch (view) {
                              _View.home => _sessionCard(),
                              _View.hosting => _hostingPanel(_host!),
                              _View.joining => _joinPanel(),
                            },
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
      ),
    );
  }

  Widget _deviceChip() {
    final colors = AppColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: context.l10n.renameDevice,
        child: Material(
          color: colors.surface,
          shape: StadiumBorder(side: BorderSide(color: colors.divider)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _starting ? null : _editDeviceName,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.monitorSmartphone,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${context.l10n.currentDevice} · ',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        widget.storage.settings.deviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      LucideIcons.pencil,
                      size: 15,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sessionCard() {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.createSession, style: textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              context.l10n.createSessionDetail,
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            ConnectionDiagram(deviceName: widget.storage.settings.deviceName),
            if (_hostError != null) ...[
              const SizedBox(height: 12),
              Text(
                context.l10n.startFailed(context.l10n.diagnostic(_hostError!)),
                style: TextStyle(color: colors.danger),
              ),
            ],
            const SizedBox(height: 20),
            GradientFilledButton.icon(
              onPressed: _starting ? null : _startHost,
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
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    context.l10n.orDivider,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(44, 50)),
              onPressed: _starting ? null : () => _setJoining(true),
              icon: const Icon(LucideIcons.logIn, size: 18),
              label: Text(context.l10n.joinSession),
            ),
          ],
        ),
      ),
    );
  }

  Widget _joinPanel() => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.nearbySessions,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: context.l10n.searchAgain,
                icon: const Icon(LucideIcons.refreshCw, size: 20),
                onPressed: _discovery.restart,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 220),
            child: ListenableBuilder(
              listenable: _discovery,
              builder: (context, _) => _nearbySessions(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            child: TextButton.icon(
              onPressed: _showManualAddress,
              icon: const Icon(LucideIcons.link, size: 18),
              label: Text(context.l10n.enterAddress),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _hostingPanel(HostSession host) {
    return ListenableBuilder(
      listenable: host,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: HostAddressCard(session: host),
            ),
          ),
          const SizedBox(height: 20),
          GradientFilledButton.icon(
            onPressed: _openHostChat,
            icon: const Icon(LucideIcons.arrowRight, size: 20),
            label: Text(context.l10n.enterSession(host.peers.length)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _confirmStopHost,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.of(context).danger,
            ),
            child: Text(context.l10n.endSession),
          ),
        ],
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

  Future<void> _showManualAddress() async {
    final target = await showDialog<(String, int)>(
      context: context,
      builder: (context) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              final parsed = _parseAddress(_manualAddress.text);
              if (parsed == null) {
                setDialogState(() => errorText = context.l10n.invalidAddress);
              } else {
                Navigator.pop(context, parsed);
              }
            }

            return AlertDialog(
              title: Text(context.l10n.enterAddress),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.manualAddressHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _manualAddress,
                    autofocus: true,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => submit(),
                    onChanged: (_) {
                      if (errorText != null) {
                        setDialogState(() => errorText = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: '192.168.1.8:8686',
                      labelText: context.l10n.sessionAddress,
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.cancel),
                ),
                FilledButton(
                  onPressed: submit,
                  child: Text(context.l10n.connectDevice),
                ),
              ],
            );
          },
        );
      },
    );
    if (target != null && mounted) {
      unawaited(_connect(target.$1, target.$2));
    }
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
