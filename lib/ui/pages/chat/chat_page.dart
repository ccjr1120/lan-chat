import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../client/client_session.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/peer.dart';
import '../../../core/session/chat_session.dart';
import '../../../l10n/ui_strings.dart';
import '../../../server/host_session.dart';
import '../../format.dart';
import '../../theme.dart';
import '../../widgets/host_address_card.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/motion.dart';
import '../../widgets/settings_menu.dart';
import '../../widgets/workspace_panel.dart';

/// 聊天页：主机与客户端共用，通过 [ChatSession] 区分行为。
///
/// 客户端会话由本页持有，返回首页时断开连接；
/// 主机会话由首页持有（返回首页后服务继续运行），加入请求弹窗也由首页统一处理。
class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.session, required this.ownsSession});

  final ChatSession session;

  /// 为 true 时页面销毁会一并结束会话。
  final bool ownsSession;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  int _lastCount = 0;

  /// 已进入过列表的消息 id，滚动重建时不重放入场动画。
  final Set<String> _seenMessageIds = {};

  ChatSession get session => widget.session;

  @override
  void initState() {
    super.initState();
    session.addListener(_onSessionChanged);
    _lastCount = session.messages.length;
    _seenMessageIds.addAll(session.messages.map((m) => m.id));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(jump: true),
    );
  }

  @override
  void dispose() {
    session.removeListener(_onSessionChanged);
    // dispose 内部会结束会话（断开连接）。
    if (widget.ownsSession) session.dispose();
    _input.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) return;
    // 一次到达多条（客户端加入后的 history 回填）视为历史，直接显示不逐条入场。
    final unseen = session.messages
        .map((m) => m.id)
        .where((id) => !_seenMessageIds.contains(id))
        .toList();
    if (unseen.length > 1) _seenMessageIds.addAll(unseen);
    final count = session.messages.length + session.outgoing.length;
    if (count != _lastCount) {
      _lastCount = count;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom({bool jump = false}) {
    if (!_scroll.hasClients) return;
    final target = _scroll.position.maxScrollExtent;
    if (jump) {
      _scroll.jumpTo(target);
    } else {
      unawaited(
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
    }
  }

  bool get _canSend => session.status == SessionStatus.connected;

  // ---------------------------------------------------------------------------
  // 操作

  Future<void> _sendText() async {
    final strings = context.l10n;
    final text = _input.text.trim();
    if (text.isEmpty || !_canSend) return;
    try {
      await session.sendText(text);
      _input.clear();
    } catch (e) {
      _toast(strings.sendFailed(strings.diagnostic(e.toString())));
    }
    if (mounted) _inputFocus.requestFocus();
  }

  Future<void> _pickAndSendFiles() async {
    final strings = context.l10n;
    if (!_canSend) return;
    List<PlatformFile> picked;
    try {
      picked = await FilePicker.pickFiles(dialogTitle: strings.chooseFiles);
    } catch (e) {
      _toast(strings.filePickerFailed(strings.diagnostic(e.toString())));
      return;
    }
    for (final file in picked) {
      final size = file.lengthSync() ?? await file.length() ?? 0;
      final source = LocalFileSource(
        name: file.name,
        size: size,
        openRead: file.readAsByteStream,
      );
      // 逐个发送，失败的文件保留在列表中显示错误。
      try {
        await session.sendFile(source);
      } catch (e) {
        _toast(strings.fileSendFailed((file.name).toString()));
      }
    }
  }

  Future<void> _openFile(FileMeta file) async {
    final strings = context.l10n;
    try {
      final path = await session.ensureLocal(file);
      final result = await OpenFilex.open(path, type: file.mime);
      if (result.type == ResultType.noAppToOpen) {
        _toast(strings.noAppForFile);
      } else if (result.type != ResultType.done) {
        _toast(strings.openFailed((result.message).toString()));
      }
    } catch (e) {
      _toast(strings.openFailed(strings.diagnostic(_describe(e))));
    }
  }

  Future<void> _shareFile(FileMeta file) async {
    final strings = context.l10n;
    final box = context.findRenderObject() as RenderBox?;
    try {
      final path = await session.ensureLocal(file);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: file.mime, name: file.name)],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      _toast(strings.shareFailed(strings.diagnostic(_describe(e))));
    }
  }

  Future<void> _copyText(String text) async {
    final strings = context.l10n;
    await Clipboard.setData(ClipboardData(text: text));
    _toast(strings.copied);
  }

  void _showSessionInfo() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _SessionInfo(session: session),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearHistory(HostSession host) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.clearHistory),
        content: Text(context.l10n.clearHistoryDetail),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.of(context).danger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.clear),
          ),
        ],
      ),
    );
    if (ok == true) await host.clearHistory();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _describe(Object e) => e is StateError
      ? e.message
      : e.toString().replaceFirst(RegExp(r'^\w+Exception: '), '');

  // ---------------------------------------------------------------------------
  // 界面

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final s = session;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.isHost ? context.l10n.mySession : s.title,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _subtitle(s),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.of(context).textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              const SettingsMenu(),
              IconButton(
                tooltip: s.isHost
                    ? context.l10n.sessionSettings
                    : context.l10n.sessionInfo,
                icon: Badge(
                  isLabelVisible:
                      s is HostSession && s.pendingRequests.isNotEmpty,
                  child: Icon(s.isHost ? LucideIcons.qrCode : LucideIcons.info),
                ),
                onPressed: _showSessionInfo,
              ),
              if (s is HostSession)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'clear') unawaited(_confirmClearHistory(s));
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'clear',
                      child: Text(context.l10n.clearHistory),
                    ),
                  ],
                ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              return Row(
                children: [
                  if (wide)
                    _DeviceSidebar(session: s, onInvite: _showSessionInfo),
                  Expanded(
                    child: Column(
                      children: [
                        _StatusBanner(session: s),
                        Expanded(
                          child: WorkspaceBackground(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 880,
                                ),
                                child: AnimatedSwitcher(
                                  duration: AppMotion.durationOf(context),
                                  switchInCurve: AppMotion.curve,
                                  switchOutCurve: AppMotion.curve,
                                  child: KeyedSubtree(
                                    key: ValueKey(_bodyStateKey(s)),
                                    child: _buildBody(s),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        _Composer(
                          controller: _input,
                          focusNode: _inputFocus,
                          enabled: _canSend,
                          onSend: _sendText,
                          onAttach: _pickAndSendFiles,
                        ),
                      ],
                    ),
                  ),
                  if (constraints.maxWidth >= 1280)
                    _RecentFiles(session: s, onOpen: _openFile),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _subtitle(ChatSession s) {
    switch (s.status) {
      case SessionStatus.connected:
        return context.l10n.connectedDevices(s.peers.length);
      case SessionStatus.connecting:
        return context.l10n.connecting;
      case SessionStatus.pending:
        return context.l10n.awaitingApproval;
      case SessionStatus.rejected:
        return context.l10n.rejected;
      case SessionStatus.disconnected:
        return context.l10n.disconnected;
      case SessionStatus.closed:
        return context.l10n.sessionEnded;
    }
  }

  /// 主体区域切换动画的分组键：状态/空态变化时淡入淡出，列表内更新不重放。
  String _bodyStateKey(ChatSession s) {
    if (s.status == SessionStatus.pending) return 'pending';
    if (s.status == SessionStatus.rejected) return 'rejected';
    if (s.messages.isEmpty && s.outgoing.isEmpty) return 'empty';
    return 'list';
  }

  Widget _buildBody(ChatSession s) {
    if (s.status == SessionStatus.pending) {
      return _CenteredState(
        icon: LucideIcons.hourglass,
        title: context.l10n.awaitingApproval,
        detail: context.l10n.approvalPendingDetail,
        showProgress: true,
      );
    }
    if (s.status == SessionStatus.rejected) {
      return _CenteredState(
        icon: LucideIcons.circleSlash,
        title: context.l10n.unableToJoin,
        detail:
            (s.statusMessage == null
                ? null
                : context.l10n.diagnostic(s.statusMessage!)) ??
            context.l10n.joinRejected,
        action: FilledButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(context.l10n.back),
        ),
      );
    }
    final messages = s.messages;
    final outgoing = s.outgoing;
    if (messages.isEmpty && outgoing.isEmpty) {
      if (s.status == SessionStatus.connected &&
          MediaQuery.sizeOf(context).width >= 900) {
        return _DesktopStart(
          session: s,
          onSendFile: _pickAndSendFiles,
          onInvite: _showSessionInfo,
          onWrite: () => _inputFocus.requestFocus(),
        );
      }
      return _CenteredState(
        icon: LucideIcons.messagesSquare,
        title: s.status == SessionStatus.connected
            ? context.l10n.startSharing
            : context.l10n.preparingSession,
        detail: s.isHost
            ? context.l10n.inviteFirstFile
            : context.l10n.sharingHint,
        action: s.isHost
            ? OutlinedButton.icon(
                onPressed: _showSessionInfo,
                icon: const Icon(LucideIcons.qrCode, size: 18),
                label: Text(context.l10n.inviteDevice),
              )
            : null,
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: messages.length + outgoing.length,
      itemBuilder: (context, index) {
        if (index >= messages.length) {
          final transfer = outgoing[index - messages.length];
          return FadeSlideIn(
            child: OutgoingTransferBubble(
              transfer: transfer,
              onDismiss: () {
                final current = session;
                if (current is HostSession) current.dismissTransfer(transfer);
                if (current is ClientSession) {
                  current.dismissTransfer(transfer);
                }
              },
            ),
          );
        }
        final message = messages[index];
        final previous = index > 0 ? messages[index - 1] : null;
        final separated =
            previous == null ||
            message.timestamp - previous.timestamp > 5 * 60 * 1000;
        // 仅新到达的消息播放入场动画；add 返回 true 表示首次出现。
        final animateEntrance = _seenMessageIds.add(message.id);
        return Column(
          children: [
            if (separated)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  formatTime(
                    message.timestamp,
                    locale: context.l10n.localeName,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.of(context).textSecondary,
                  ),
                ),
              ),
            FadeSlideIn(
              key: ValueKey(message.id),
              enabled: animateEntrance,
              child: MessageBubble(
                showSender:
                    separated || previous.sender.id != message.sender.id,
                message: message,
                isSelf: message.sender.id == s.self.id,
                session: s,
                onOpenFile: _openFile,
                onShareFile: _shareFile,
                onCopyText: _copyText,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.session});

  final ChatSession session;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final String? text;
    final Color color;
    switch (s.status) {
      case SessionStatus.connecting:
        text =
            (s.statusMessage == null
                ? null
                : context.l10n.diagnostic(s.statusMessage!)) ??
            context.l10n.connectingNow;
        color = AppColors.of(context).warning;
      case SessionStatus.disconnected:
        text =
            (s.statusMessage == null
                ? null
                : context.l10n.diagnostic(s.statusMessage!)) ??
            context.l10n.reconnecting;
        color = AppColors.of(context).warning;
      default:
        text = null;
        color = AppColors.of(context).warning;
    }
    final duration = AppMotion.durationOf(context);
    return AnimatedSize(
      duration: duration,
      curve: AppMotion.curve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: AppMotion.curve,
        switchOutCurve: AppMotion.curve,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.3),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: text == null
            ? const SizedBox.shrink(key: ValueKey('hidden'))
            : Material(
                key: ValueKey(text),
                color: color.withValues(alpha: 0.12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.wifiOff, size: 18, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(color: color, fontSize: 13),
                        ),
                      ),
                      if (s is ClientSession &&
                          s.status == SessionStatus.disconnected)
                        TextButton(
                          onPressed: s.retryNow,
                          child: Text(context.l10n.retryNow),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.of(context).surface,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: ListenableBuilder(
                listenable: focusNode,
                builder: (context, _) {
                  final focused = focusNode.hasFocus;
                  final colors = AppColors.of(context);
                  return AnimatedContainer(
                    duration: AppMotion.durationOf(context),
                    curve: AppMotion.curve,
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: focused ? colors.primary : colors.divider,
                        width: focused ? 1.5 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: context.l10n.sendFile,
                          icon: const Icon(LucideIcons.paperclip, size: 22),
                          onPressed: enabled ? onAttach : null,
                        ),
                        Expanded(
                          child: Focus(
                            onKeyEvent: (_, event) {
                              final composing = controller.value.composing;
                              if (!enabled ||
                                  event is! KeyDownEvent ||
                                  event.logicalKey !=
                                      LogicalKeyboardKey.enter ||
                                  HardwareKeyboard.instance.isShiftPressed ||
                                  (composing.isValid &&
                                      !composing.isCollapsed)) {
                                return KeyEventResult.ignored;
                              }
                              onSend();
                              return KeyEventResult.handled;
                            },
                            child: TextField(
                              controller: controller,
                              focusNode: focusNode,
                              enabled: enabled,
                              minLines: 1,
                              maxLines: 5,
                              textInputAction: TextInputAction.newline,
                              decoration: InputDecoration(
                                hintText: enabled
                                    ? context.l10n.messageHint
                                    : context.l10n.connectBeforeSending,
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: controller,
                          builder: (context, value, _) => IconButton.filled(
                            tooltip: context.l10n.send,
                            icon: const Icon(LucideIcons.arrowUp, size: 22),
                            style:
                                IconButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ).copyWith(
                                  // 可发送时与主操作按钮一致使用 primaryGradient；
                                  // Ink 绘制在按钮 Material 上，水波纹仍可见。
                                  backgroundBuilder: (context, states, child) =>
                                      states.contains(WidgetState.disabled)
                                      ? child!
                                      : Ink(
                                          decoration: BoxDecoration(
                                            gradient: AppColors.of(
                                              context,
                                            ).primaryGradient,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: child,
                                        ),
                                ),
                            onPressed: enabled && value.text.trim().isNotEmpty
                                ? onSend
                                : null,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    required this.detail,
    this.showProgress = false,
    this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool showProgress;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.of(context).selfBubble,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 32, color: AppColors.of(context).primary),
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.of(context).textSecondary),
            ),
            if (showProgress) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// 底部弹层：主机显示访问地址/访问控制，两端都显示在线设备。
class _SessionInfo extends StatelessWidget {
  const _SessionInfo({required this.session});

  final ChatSession session;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final s = session;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (s is HostSession) ...[
              HostAddressCard(session: s),
              const Divider(height: 32),
            ],
            if (s is ClientSession) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.router),
                title: Text(s.title),
                subtitle: Text(
                  context.l10n.hostAddress((s.address).toString()),
                ),
              ),
              const Divider(height: 24),
            ],
            Text(
              context.l10n.onlineDevicesCount(s.peers.length),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            for (final peer in s.peers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(switch (peer.platform) {
                  PeerPlatform.host => LucideIcons.radio,
                  PeerPlatform.app => LucideIcons.smartphone,
                  PeerPlatform.web => LucideIcons.globe,
                }),
                title: Text(
                  peer.id == s.self.id
                      ? context.l10n.peerIsMe((peer.name).toString())
                      : peer.name,
                ),
                subtitle: Text(context.l10n.platformLabel(peer.platform)),
              ),
          ],
        );
      },
    );
  }
}

/// 宽屏常驻设备栏，窄屏继续通过会话详情访问。
class _DeviceSidebar extends StatelessWidget {
  const _DeviceSidebar({required this.session, required this.onInvite});
  final ChatSession session;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) => Container(
    width: 256,
    decoration: BoxDecoration(
      color: AppColors.of(context).surface,
      border: Border(right: BorderSide(color: AppColors.of(context).divider)),
    ),
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(
          LucideIcons.monitorSmartphone,
          size: 30,
          color: AppColors.of(context).primary,
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.currentSession,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        Text(session.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onInvite,
          icon: Icon(
            session.isHost ? LucideIcons.qrCode : LucideIcons.info,
            size: 18,
          ),
          label: Text(
            session.isHost
                ? context.l10n.inviteDevice
                : context.l10n.sessionDetails,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          context.l10n.onlineDevices(session.peers.length),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        for (final peer in session.peers)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              peer.platform == PeerPlatform.web
                  ? LucideIcons.globe
                  : peer.platform == PeerPlatform.host
                  ? LucideIcons.radio
                  : LucideIcons.smartphone,
              size: 20,
              color: AppColors.of(context).textSecondary,
            ),
            title: Text(
              peer.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              peer.id == session.self.id
                  ? context.l10n.myDevice
                  : context.l10n.platformLabel(peer.platform),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          context.l10n.networkSharingHint,
          style: TextStyle(
            fontSize: 12,
            height: 1.6,
            color: AppColors.of(context).textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _DesktopStart extends StatelessWidget {
  const _DesktopStart({
    required this.session,
    required this.onSendFile,
    required this.onInvite,
    required this.onWrite,
  });
  final ChatSession session;
  final VoidCallback onSendFile;
  final VoidCallback onInvite;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    LucideIcons.monitorSmartphone,
                    size: 40,
                    color: AppColors.of(context).primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.devicesConnected,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  session.peers.length > 1
                      ? context.l10n.readyToShare(session.peers.length)
                      : context.l10n.sessionEmptyHint,
                  style: TextStyle(color: AppColors.of(context).textSecondary),
                ),
                const SizedBox(height: 28),
                GradientFilledButton.icon(
                  onPressed: onSendFile,
                  icon: const Icon(LucideIcons.fileUp, size: 20),
                  label: Text(context.l10n.chooseFileToSend),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: session.isHost ? onInvite : onWrite,
                  icon: Icon(
                    session.isHost
                        ? LucideIcons.qrCode
                        : LucideIcons.messageSquare,
                    size: 18,
                  ),
                  label: Text(
                    session.isHost
                        ? context.l10n.inviteOtherDevices
                        : context.l10n.writeMessage,
                  ),
                ),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 20,
                  runSpacing: 12,
                  children: [
                    _ContentHint(
                      icon: LucideIcons.fileText,
                      label: context.l10n.documentsFiles,
                    ),
                    _ContentHint(
                      icon: LucideIcons.image,
                      label: context.l10n.imagesVideos,
                    ),
                    _ContentHint(
                      icon: LucideIcons.messageSquare,
                      label: context.l10n.textLinks,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ContentHint extends StatelessWidget {
  const _ContentHint({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppColors.of(context).textSecondary),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.of(context).textSecondary,
        ),
      ),
    ],
  );
}

/// 从真实会话消息提取文件，提供桌面常驻快速打开入口。
class _RecentFiles extends StatelessWidget {
  const _RecentFiles({required this.session, required this.onOpen});
  final ChatSession session;
  final void Function(FileMeta) onOpen;

  @override
  Widget build(BuildContext context) {
    final files = session.messages
        .where((m) => m.kind == MessageKind.file && m.file != null)
        .toList()
        .reversed
        .toList();
    final totalBytes = files.fold<int>(
      0,
      (sum, message) => sum + message.file!.size,
    );
    return Container(
      width: 288,
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        border: Border(left: BorderSide(color: AppColors.of(context).divider)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            context.l10n.sessionFiles,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.fileCountSize(
              files.length,
              (formatBytes(totalBytes)).toString(),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          if (files.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.of(context).background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.folderOpen,
                    size: 28,
                    color: AppColors.of(context).primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    context.l10n.filesAppearHere,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6),
                  Text(
                    context.l10n.recentFilesHint,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.7,
                      color: AppColors.of(context).textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          for (final message in files.take(12))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HoverLift(
                borderRadius: BorderRadius.circular(12),
                child: Material(
                  color: AppColors.of(context).background,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: Icon(
                      message.file!.isImage
                          ? LucideIcons.image
                          : LucideIcons.fileText,
                      size: 22,
                      color: AppColors.of(context).primary,
                    ),
                    title: Text(
                      message.file!.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      session.downloads[message.file!.id] == null
                          ? '${formatBytes(message.file!.size)} · ${message.sender.name}'
                          : context.l10n.downloadProgress(
                              ((session.downloads[message.file!.id]! * 100)
                                      .round())
                                  .toString(),
                            ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.of(context).textSecondary,
                      ),
                    ),
                    onTap: session.downloads[message.file!.id] == null
                        ? () => onOpen(message.file!)
                        : null,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            context.l10n.recentFilesLimit,
            style: TextStyle(
              fontSize: 12,
              height: 1.7,
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
