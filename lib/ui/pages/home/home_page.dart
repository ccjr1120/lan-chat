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
import '../../widgets/theme_menu.dart';
import '../../widgets/workspace_panel.dart';
import '../chat/chat_page.dart';

enum _Mode { host, client }

/// 首页：选择服务端（主机）或客户端模式。
///
/// - 主机模式：启动/停止服务，展示二维码与 IP:端口，切换访问控制；
///   主机会话由本页持有，需确认模式下的加入请求在此统一弹窗（聊天页打开时同样生效）。
/// - 客户端模式：mDNS 发现列表 + 手动输入 IP:端口。
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.storage});

  final AppStorage storage;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  _Mode _mode = _Mode.host;
  HostSession? _host;
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

  // ---------------------------------------------------------------------------
  // 主机

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

  /// 逐个弹出加入请求；同一时间只显示一个。
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

  // ---------------------------------------------------------------------------
  // 客户端

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

  void _connectManual() {
    final parsed = _parseAddress(_manualAddress.text);
    if (parsed == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.invalidAddress)));
      return;
    }
    FocusScope.of(context).unfocus();
    unawaited(_connect(parsed.$1, parsed.$2));
  }

  /// 支持 `192.168.1.8:8686`、`192.168.1.8`（默认端口）以及完整的 http:// 地址。
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

  void _switchMode(_Mode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    if (mode == _Mode.client) {
      unawaited(_discovery.start());
    } else {
      unawaited(_discovery.stop());
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
      if (_host != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.nameNextSession)));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 界面

  /// 入场区块的 key：模式或主机运行状态变化时重建 FadeSlideIn，重放入场动效；
  /// 同一状态内的重建（启动中、错误、设备变化）保持不变。
  Key _stageKey(String slot) => ValueKey((slot, _mode, _host != null));

  @override
  Widget build(BuildContext context) {
    final joining = _mode == _Mode.client;
    final macOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    return Scaffold(
      // macOS has a native title bar at every window width.
      appBar: macOS
          ? null
          : AppBar(
              leading: joining
                  ? IconButton(
                      tooltip: context.l10n.backHome,
                      icon: const Icon(LucideIcons.arrowLeft),
                      onPressed: () => _switchMode(_Mode.host),
                    )
                  : null,
              title: Text(
                joining ? context.l10n.joinSession : context.l10n.appName,
              ),
              actions: const [ThemeMenu(), SizedBox(width: 8)],
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
                    constraints: BoxConstraints(maxWidth: wide ? 1440 : 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FadeSlideIn(
                          key: _stageKey('title'),
                          child: Row(
                            children: [
                              if (macOS && joining)
                                IconButton(
                                  tooltip: context.l10n.backHome,
                                  icon: const Icon(LucideIcons.arrowLeft),
                                  onPressed: () => _switchMode(_Mode.host),
                                ),
                              Expanded(
                                child: Text(
                                  joining
                                      ? context.l10n.findDevices
                                      : _host == null
                                      ? context.l10n.homeHeadline
                                      : context.l10n.sessionReady,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                              ),
                              if (macOS) const ThemeMenu(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        FadeSlideIn(
                          key: _stageKey('detail'),
                          delay: const Duration(milliseconds: 40),
                          child: Text(
                            joining
                                ? context.l10n.findDevicesDetail
                                : _host == null
                                ? context.l10n.homeDetail
                                : context.l10n.inviteDetail,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (joining) ...[
                          if (_host != null) ...[
                            FadeSlideIn(
                              key: _stageKey('running'),
                              delay: const Duration(milliseconds: 60),
                              child: HoverLift(
                                child: Card(
                                  child: ListTile(
                                    leading: Icon(
                                      LucideIcons.radio,
                                      color: AppColors.of(context).success,
                                    ),
                                    title: Text(
                                      context.l10n.sessionStillRunning,
                                    ),
                                    subtitle: Text(
                                      context.l10n.returnToSession,
                                    ),
                                    onTap: () => _switchMode(_Mode.host),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          FadeSlideIn(
                            key: _stageKey('body'),
                            delay: const Duration(milliseconds: 80),
                            child: _buildClient(),
                          ),
                        ] else if (wide)
                          FadeSlideIn(
                            key: _stageKey('body'),
                            delay: const Duration(milliseconds: 60),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 7, child: _buildHost()),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _deviceIdentity(),
                                      const SizedBox(height: 20),
                                      _joinCard(expanded: true),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          _deviceIdentity(),
                          const SizedBox(height: 20),
                          FadeSlideIn(
                            key: _stageKey('body'),
                            delay: const Duration(milliseconds: 80),
                            child: _buildHost(),
                          ),
                          const SizedBox(height: 16),
                          _joinCard(),
                        ],
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

  Widget _joinCard({bool expanded = false}) {
    final title = _host == null
        ? context.l10n.joinSession
        : context.l10n.joinAnotherSession;
    if (!expanded) {
      return FadeSlideIn(
        key: _stageKey('join'),
        delay: const Duration(milliseconds: 100),
        child: HoverLift(
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              leading: const _FeatureIcon(icon: LucideIcons.logIn),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(context.l10n.joinNearbyDetail),
              trailing: const Icon(LucideIcons.arrowRight, size: 20),
              onTap: () => _switchMode(_Mode.client),
            ),
          ),
        ),
      );
    }
    return FadeSlideIn(
      key: _stageKey('join'),
      delay: const Duration(milliseconds: 100),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: _FeatureIcon(icon: LucideIcons.logIn, large: true),
              ),
              const SizedBox(height: 20),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                context.l10n.findDevicesDetail,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _switchMode(_Mode.client),
                icon: const Icon(LucideIcons.arrowRight, size: 18),
                label: Text(context.l10n.joinSession),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deviceIdentity() => FadeSlideIn(
    key: _stageKey('device'),
    delay: const Duration(milliseconds: 60),
    child: HoverLift(
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 6,
          ),
          leading: const _FeatureIcon(icon: LucideIcons.monitorSmartphone),
          title: Text(
            widget.storage.settings.deviceName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(context.l10n.myDeviceRename),
          trailing: Icon(
            LucideIcons.pencil,
            size: 17,
            color: AppColors.of(context).textSecondary,
          ),
          onTap: _editDeviceName,
        ),
      ),
    ),
  );

  Widget _buildHost() {
    final host = _host;
    if (host == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.createSession,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.createSessionDetail,
                style: TextStyle(color: AppColors.of(context).textSecondary),
              ),
              const SizedBox(height: 20),
              ConnectionDiagram(deviceName: widget.storage.settings.deviceName),
              if (_hostError != null) ...[
                const SizedBox(height: 12),
                Text(
                  context.l10n.startFailed(
                    context.l10n.diagnostic(_hostError!),
                  ),
                  style: TextStyle(color: AppColors.of(context).danger),
                ),
              ],
              const SizedBox(height: 24),
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
            ],
          ),
        ),
      );
    }
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

  Widget _buildClient() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListenableBuilder(
        listenable: _discovery,
        builder: (context, _) {
          final hosts = _discovery.hosts;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.nearbySessions,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: context.l10n.searchAgain,
                        icon: const Icon(LucideIcons.refreshCw, size: 20),
                        onPressed: _discovery.restart,
                      ),
                    ],
                  ),
                  if (hosts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          const _FeatureIcon(
                            icon: LucideIcons.radar,
                            large: true,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _discovery.error == null
                                ? context.l10n.searchingDevices
                                : context.l10n.discoveryFailed,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (_discovery.error == null
                                    ? null
                                    : context.l10n.diagnostic(
                                        _discovery.error!,
                                      )) ??
                                context.l10n.nearbyHint,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (_discovery.error == null) ...[
                            const SizedBox(height: 20),
                            const SizedBox(
                              width: 100,
                              child: LinearProgressIndicator(minHeight: 3),
                            ),
                          ],
                        ],
                      ),
                    ),
                  for (final h in hosts)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
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
                ],
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 16),
      Card(
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: const Icon(LucideIcons.link, size: 20),
          title: Text(
            context.l10n.enterAddress,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(context.l10n.manualAddressHint),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            TextField(
              controller: _manualAddress,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _connectManual(),
              decoration: InputDecoration(
                hintText: '192.168.1.8:8686',
                labelText: context.l10n.sessionAddress,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GradientFilledButton(
                onPressed: _connectManual,
                label: Text(context.l10n.connectDevice),
              ),
            ),
          ],
        ),
      ),
    ],
  );
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
