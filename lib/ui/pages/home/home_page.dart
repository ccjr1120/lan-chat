import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../client/client_session.dart';
import '../../../l10n/ui_strings.dart';
import '../../../server/host_session.dart';
import '../../../storage/app_storage.dart';
import '../../theme.dart';
import '../../widgets/feature_icon.dart';
import '../../widgets/join_request_dialog.dart';
import '../../widgets/mascot.dart';
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
  final TextEditingController _manualAddress = TextEditingController();
  String? _manualError;
  String? _requestInDialog;

  @override
  void dispose() {
    _host?.removeListener(_onHostChanged);
    _host?.dispose();
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(session: host!, ownsSession: false),
      ),
    );
    await _stopHost();
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(session: session, ownsSession: true),
      ),
    );
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
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      // macOS has a native title bar at every window width.
      appBar: macOS
          ? null
          : AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ExcludeSemantics(child: MascotLogo(size: 28)),
                  const SizedBox(width: 8),
                  Flexible(child: Text(context.l10n.appName)),
                ],
              ),
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - (wide ? 56 : 40)).clamp(
                      0,
                      double.infinity,
                    ),
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
                                if (macOS) ...[
                                  const MascotLogo(size: 40),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Text(
                                    context.l10n.homeHeadline,
                                    style: constraints.maxWidth < 600
                                        ? textTheme.headlineSmall
                                        : textTheme.headlineMedium,
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
                        ],
                      ),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FeatureIcon(icon: LucideIcons.radio),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.createSession,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.l10n.createSessionDetail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                      child: MascotLoader(
                        anim: MascotAnim.paw,
                        size: 18,
                        mini: true,
                      ),
                    )
                  : const Icon(LucideIcons.plus, size: 20),
              label: Text(
                _starting
                    ? context.l10n.creatingSession
                    : context.l10n.createSession,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                const FeatureIcon(icon: LucideIcons.link),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.connectDevice,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _manualAddressEntry(),
          ],
        ),
      ),
    );
  }

  Widget _manualAddressEntry() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextField(
        controller: _manualAddress,
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
}
