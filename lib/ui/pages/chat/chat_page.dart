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
import '../../widgets/feature_icon.dart';
import '../../widgets/host_address_card.dart';
import '../../widgets/mascot.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/motion.dart';
import '../../widgets/workspace_panel.dart';

/// 聊天页：主机与客户端共用，通过 [ChatSession] 区分行为。
///
/// 客户端会话由本页持有，返回首页时断开连接；
/// 主机会话由首页持有，返回首页后结束；加入请求弹窗由首页统一处理。
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
  bool _showInvite = false;

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

  /// 仅当有其他设备在线时才确认；没有人在线可直接结束。
  Future<bool> _confirmEndSession(HostSession host) async {
    if (host.peers.length <= 1) return true;
    final ok = await showDialog<bool>(
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
    return ok == true;
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
        final host = s is HostSession ? s : null;
        return PopScope(
          // 主机离开聊天页即结束会话；有其他设备在线时先确认。
          canPop: host == null || host.peers.length <= 1,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop || host == null) return;
            final ok = await _confirmEndSession(host);
            if (ok && mounted) Navigator.of(this.context).pop();
          },
          child: Scaffold(
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
                _PeersMenu(session: s),
                if (host != null)
                  IconButton(
                    tooltip: _showInvite
                        ? context.l10n.hideInvitePanel
                        : context.l10n.showInvitePanel,
                    icon: const Icon(LucideIcons.qrCode),
                    isSelected: _showInvite,
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() => _showInvite = !_showInvite);
                    },
                  ),
              ],
            ),
            body: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    _StatusBanner(session: s),
                    Expanded(
                      child: WorkspaceBackground(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 880),
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
                if (host != null && _showInvite) _InvitePanel(session: host),
              ],
            ),
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
        art: MascotLoader(
          anim: MascotAnim.blink,
          size: 96,
          semanticLabel: context.l10n.awaitingApproval,
        ),
        title: context.l10n.awaitingApproval,
        detail: context.l10n.approvalPendingDetail,
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
      return _CenteredState(
        icon: LucideIcons.messagesSquare,
        art: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FeatureIcon(icon: LucideIcons.messageCircle, size: 36),
            SizedBox(width: 12),
            MascotLoader(anim: MascotAnim.sleep, size: 96),
            SizedBox(width: 12),
            FeatureIcon(icon: LucideIcons.fileUp, size: 36),
          ],
        ),
        subtleTitle: s.isHost && s.status == SessionStatus.connected,
        title: s.status == SessionStatus.connected
            ? (s.isHost
                  ? context.l10n.inviteFirstFile
                  : context.l10n.sharingHint)
            : context.l10n.preparingSession,
        detail: s.status == SessionStatus.connected
            ? null
            : (s.isHost
                  ? context.l10n.inviteFirstFile
                  : context.l10n.sharingHint),
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
                            style: IconButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
    this.art,
    this.action,
    this.subtleTitle = false,
  });

  final bool subtleTitle;
  final IconData icon;
  final String title;
  final String? detail;

  /// 传入时替代图标容器（吉祥物动画）。
  final Widget? art;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            art ??
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).selfBubble,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: AppColors.of(context).primary,
                  ),
                ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style:
                    (subtleTitle
                            ? Theme.of(context).textTheme.bodyMedium
                            : Theme.of(context).textTheme.titleMedium)
                        ?.copyWith(
                          height: 1.7,
                          color: subtleTitle
                              ? AppColors.of(context).textSecondary
                              : null,
                        ),
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.of(context).textSecondary),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// 顶栏在线设备入口：轻量下拉列表，替代常驻侧栏与底部弹层。
class _PeersMenu extends StatelessWidget {
  const _PeersMenu({required this.session});
  final ChatSession session;

  @override
  Widget build(BuildContext context) {
    final secondary = AppColors.of(context).textSecondary;
    return PopupMenuButton<void>(
      position: PopupMenuPosition.under,
      tooltip: context.l10n.onlineDevicesCount(session.peers.length),
      itemBuilder: (_) => [
        for (final peer in session.peers)
          PopupMenuItem<void>(
            child: Row(
              children: [
                FeatureIcon(
                  size: 36,
                  icon: switch (peer.platform) {
                    PeerPlatform.host => LucideIcons.radio,
                    PeerPlatform.app => LucideIcons.smartphone,
                    PeerPlatform.web => LucideIcons.globe,
                  },
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    peer.id == session.self.id
                        ? context.l10n.peerIsMe(peer.name)
                        : peer.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.l10n.platformLabel(peer.platform),
                  style: TextStyle(fontSize: 12, color: secondary),
                ),
              ],
            ),
          ),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.users, size: 20, color: secondary),
              const SizedBox(width: 4),
              Text(
                '${session.peers.length}',
                style: TextStyle(color: secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 覆盖聊天主体的连接信息面板，顶部按钮保持可用。
class _InvitePanel extends StatelessWidget {
  const _InvitePanel({required this.session});
  final HostSession session;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.of(context).surface,
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: HostAddressCard(session: session),
          ),
        ),
      ),
    ),
  );
}
