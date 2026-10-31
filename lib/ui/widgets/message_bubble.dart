import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/chat_message.dart';
import '../../core/models/peer.dart';
import '../../core/session/chat_session.dart';
import '../../l10n/ui_strings.dart';
import '../format.dart';
import '../theme.dart';

/// 聊天气泡：文字消息可长按复制；文件消息点击打开、菜单分享。
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isSelf,
    required this.session,
    required this.onOpenFile,
    required this.onShareFile,
    required this.onCopyText,
    this.showSender = true,
  });

  final bool showSender;
  final ChatMessage message;
  final bool isSelf;
  final ChatSession session;
  final void Function(FileMeta file) onOpenFile;
  final void Function(FileMeta file) onShareFile;
  final void Function(String text) onCopyText;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.8;
    final sender = message.sender;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      // 父级 Column 默认居中且本 Column 宽度随内容收缩，需显式对齐到发送方一侧：
      // 自己的消息靠右，其他人的消息靠左。
      child: Align(
        alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isSelf
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (showSender)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                child: Text(
                  '${isSelf ? context.l10n.me : sender.name}'
                  '${sender.platform == PeerPlatform.host && !isSelf ? context.l10n.hostSuffix : ''}'
                  ' · ${formatTime(message.timestamp, locale: context.l10n.localeName)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.of(context).textSecondary,
                  ),
                ),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth > 520 ? 520 : maxWidth,
              ),
              child: message.kind == MessageKind.file && message.file != null
                  ? _FileBubble(
                      file: message.file!,
                      isSelf: isSelf,
                      session: session,
                      onOpen: onOpenFile,
                      onShare: onShareFile,
                    )
                  : _TextBubble(
                      text: message.text ?? '',
                      isSelf: isSelf,
                      onCopy: onCopyText,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 气泡圆角：尾角（小圆角）位于发送方一侧的底部。
BorderRadius _bubbleRadius(bool isSelf) => BorderRadius.only(
  topLeft: const Radius.circular(16),
  topRight: const Radius.circular(16),
  bottomLeft: Radius.circular(isSelf ? 16 : 4),
  bottomRight: Radius.circular(isSelf ? 4 : 16),
);

/// `filled` 为 false 时（文件气泡）使用 surface 底色以保证文件图标对比度，
/// 尾角方向仍跟随 [isSelf]。
BoxDecoration _bubbleDecoration(
  BuildContext context,
  bool isSelf, {
  bool filled = true,
}) {
  final colors = AppColors.of(context);
  final accent = isSelf && filled;
  return BoxDecoration(
    // 自己发送的文字气泡使用浅色强调底；其余气泡保持 surface。
    color: accent ? colors.selfBubble : colors.otherBubble,
    borderRadius: _bubbleRadius(isSelf),
    border: Border.all(
      color: accent ? colors.primary.withValues(alpha: 0.18) : colors.divider,
    ),
  );
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({
    required this.text,
    required this.isSelf,
    required this.onCopy,
  });

  final String text;
  final bool isSelf;
  final void Function(String text) onCopy;

  @override
  Widget build(BuildContext context) {
    final selectable = SelectableText(
      text,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: AppColors.of(context).textPrimary,
      ),
    );
    return GestureDetector(
      onLongPress: () => onCopy(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: _bubbleDecoration(context, isSelf),
        child: selectable,
      ),
    );
  }
}

class _FileBubble extends StatelessWidget {
  const _FileBubble({
    required this.file,
    required this.isSelf,
    required this.session,
    required this.onOpen,
    required this.onShare,
  });

  final FileMeta file;
  final bool isSelf;
  final ChatSession session;
  final void Function(FileMeta file) onOpen;
  final void Function(FileMeta file) onShare;

  @override
  Widget build(BuildContext context) {
    final progress = session.downloads[file.id];
    final fg = AppColors.of(context).textPrimary;
    final sub = AppColors.of(context).textSecondary;
    return Semantics(
      button: true,
      label: context.l10n.fileAccessibility(
        (file.name).toString(),
        (formatBytes(file.size)).toString(),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: _bubbleRadius(isSelf),
          onTap: progress == null ? () => onOpen(file) : null,
          child: Ink(
            decoration: _bubbleDecoration(context, isSelf, filled: false),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (file.isImage) _ImagePreview(file: file, session: session),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.of(context).selfBubble,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconFor(file),
                        color: AppColors.of(context).primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            progress == null
                                ? context.l10n.fileOpenHint(
                                    (formatBytes(file.size)).toString(),
                                  )
                                : context.l10n.downloadProgress(
                                    ((progress * 100).toStringAsFixed(
                                      0,
                                    )).toString(),
                                  ),
                            style: TextStyle(color: sub, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.share,
                      icon: Icon(LucideIcons.share2, color: sub, size: 20),
                      onPressed: progress == null ? () => onShare(file) : null,
                    ),
                  ],
                ),
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: AppColors.of(context).divider,
                    color: AppColors.of(context).primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(FileMeta file) {
    final mime = file.mime;
    if (mime.startsWith('image/')) return LucideIcons.image;
    if (mime.startsWith('video/')) return LucideIcons.video;
    if (mime.startsWith('audio/')) return LucideIcons.music;
    if (mime == 'application/pdf') return LucideIcons.fileText;
    if (mime.contains('zip') || mime.contains('compressed')) {
      return LucideIcons.archive;
    }
    if (mime.startsWith('text/')) return LucideIcons.fileText;
    return LucideIcons.file;
  }
}

/// 图片已在本地时显示缩略图（主机始终在本地，客户端下载后显示）。
class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.file, required this.session});

  final FileMeta file;
  final ChatSession session;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: session.localPathFor(file),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                cacheWidth: 600,
                semanticLabel: file.name,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 发送中的文件气泡（右侧）。
class OutgoingTransferBubble extends StatelessWidget {
  const OutgoingTransferBubble({
    super.key,
    required this.transfer,
    required this.onDismiss,
  });

  final OutgoingTransfer transfer;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final failed = transfer.error != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.of(context).surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: failed
                    ? AppColors.of(context).danger
                    : AppColors.of(context).divider,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      failed ? LucideIcons.circleAlert : LucideIcons.fileUp,
                      color: failed
                          ? AppColors.of(context).danger
                          : AppColors.of(context).primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transfer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (failed)
                      IconButton(
                        tooltip: context.l10n.remove,
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: onDismiss,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (failed)
                  Text(
                    context.l10n.diagnostic(transfer.error!),
                    style: TextStyle(
                      color: AppColors.of(context).danger,
                      fontSize: 12,
                    ),
                  )
                else ...[
                  LinearProgressIndicator(
                    value: transfer.progress,
                    minHeight: 4,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatBytes(transfer.sent)} / ${formatBytes(transfer.size)}'
                    '  ${(transfer.progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.of(context).textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
