import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../data/chat_repository.dart';
import '../data/chat_text_formatter.dart';
import '../utils/chat_system_event.dart';
import 'conversation_media_widgets.dart';

class ConversationDateDivider extends StatelessWidget {
  final DateTime date;

  const ConversationDateDivider({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final value = DateTime(local.year, local.month, local.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final label =
        value == today
            ? 'Hoje'
            : value == yesterday
            ? 'Ontem'
            : '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
    final chrome = ShellChrome.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
      child: Center(
        child: Text(
          label,
          style: FocuxHubTypography.chip(chrome.mute),
        ),
      ),
    );
  }
}

class ConversationOlderMessagesLoader extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const ConversationOlderMessagesLoader({
    super.key,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: TextButton(
        onPressed: loading ? null : onTap,
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        child:
            loading
                ? SizedBox(
                  width: 16,
                  height: 16,
                  child: FxLoading(strokeWidth: 2, color: primary),
                )
                : Text(
                  'Carregar mensagens antigas',
                  style: FocuxHubTypography.chip(primary),
                ),
      ),
    );
  }
}

class ConversationDeliveryStatus extends StatelessWidget {
  final ChatMsg msg;
  final Color color;

  const ConversationDeliveryStatus({
    super.key,
    required this.msg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final read = msg.readAt != null;
    final delivered = msg.deliveredAt != null;
    final label =
        read
            ? 'Lido'
            : delivered
            ? 'Entregue'
            : 'Enviado';
    return Text(
      label,
      style: FocuxHubTypography.chip(color),
    );
  }
}

class ConversationTypingIndicator extends StatefulWidget {
  final bool isDark;
  final Color accentColor;

  const ConversationTypingIndicator({
    super.key,
    required this.isDark,
    required this.accentColor,
  });

  @override
  State<ConversationTypingIndicator> createState() =>
      _ConversationTypingIndicatorState();
}

class _ConversationTypingIndicatorState
    extends State<ConversationTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensStrip.s3,
        vertical: TokensStrip.s3,
      ),
      decoration: BoxDecoration(
        color: chrome.cardFill,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        border: Border.all(color: chrome.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = ((_ctrl.value + (i / 3)) % 1.0);
              final opacity = t < 0.5 ? 0.3 + t * 1.4 : 1.0 - (t - 0.5) * 1.4;
              return Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accentColor.withValues(
                    alpha: opacity.clamp(0.3, 1.0),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class ConversationSwipeReplyWrapper extends StatefulWidget {
  final Widget child;
  final bool alignRight;
  final Color accentColor;
  final VoidCallback onReply;

  const ConversationSwipeReplyWrapper({
    super.key,
    required this.child,
    required this.alignRight,
    required this.accentColor,
    required this.onReply,
  });

  @override
  State<ConversationSwipeReplyWrapper> createState() =>
      _ConversationSwipeReplyWrapperState();
}

class _ConversationSwipeReplyWrapperState
    extends State<ConversationSwipeReplyWrapper> {
  double _offset = 0;
  bool _triggered = false;

  void _handleUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    final next =
        widget.alignRight
            ? (_offset + delta).clamp(-54.0, 0.0)
            : (_offset + delta).clamp(0.0, 54.0);
    if (!_triggered && next.abs() >= 34) {
      _triggered = true;
      HapticFeedback.lightImpact();
      widget.onReply();
    }
    setState(() => _offset = next);
  }

  void _reset() {
    if (mounted) {
      setState(() => _offset = 0);
    }
    _triggered = false;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.86,
      child: Stack(
        clipBehavior: Clip.none,
        alignment:
            widget.alignRight ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          Positioned(
            left: widget.alignRight ? null : 6,
            right: widget.alignRight ? 6 : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: _offset.abs() > 8 ? 1 : 0,
              child: Icon(
                Icons.reply_rounded,
                color: widget.accentColor,
                size: 18,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_offset, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: _handleUpdate,
              onHorizontalDragEnd: (_) => _reset(),
              onHorizontalDragCancel: _reset,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class ConversationChatBackdrop extends StatelessWidget {
  const ConversationChatBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return ColoredBox(
      color: chrome.isDark ? EagleTokens.darkBg : TokensStrip.pageBg,
    );
  }
}

class ConversationSystemEvent extends StatelessWidget {
  final ChatMsg msg;

  const ConversationSystemEvent({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final view = formatChatSystemEvent(msg.conteudo);
    final time = _conversationTimeLabel(msg.enviadoEm);
    return Semantics(
      label: '${view.threadLabel}, $time',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TokensStrip.s4,
          vertical: TokensStrip.s3,
        ),
        child: Column(
          children: [
            Text(
              view.title,
              textAlign: TextAlign.center,
              style: FocuxHubTypography.body(color: chrome.ink).copyWith(
                fontWeight: FontWeight.w700,
                height: 1.35,
                letterSpacing: 0.15,
              ),
            ),
            if (view.detail != null) ...[
              const SizedBox(height: TokensStrip.s1),
              Text(
                view.detail!,
                textAlign: TextAlign.center,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ],
            const SizedBox(height: TokensStrip.s1),
            Text(time, style: FocuxHubTypography.chip(chrome.mute)),
          ],
        ),
      ),
    );
  }
}

class ConversationBubble extends StatelessWidget {
  final ChatMsg msg;
  final bool mine;
  final bool isDark;
  final Color accentColor;
  final bool highlighted;
  final String Function(String remetente) replyLabelBuilder;
  final VoidCallback onLongPress;
  final VoidCallback? onReplyTap;
  final VoidCallback onOpenMedia;

  const ConversationBubble({
    super.key,
    required this.msg,
    required this.mine,
    required this.isDark,
    required this.accentColor,
    required this.highlighted,
    required this.replyLabelBuilder,
    required this.onLongPress,
    required this.onReplyTap,
    required this.onOpenMedia,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final textColor = chrome.ink;
    final metaColor = chrome.mute;
    final deleted = msg.deletedAt != null;
    final displayText = formatChatTextForDisplay(msg.conteudo);
    final bubbleMaxWidth = (MediaQuery.sizeOf(context).width - 56).clamp(
      220.0,
      520.0,
    );
    final fill =
        mine ? BrandPalette.soft(accentColor, dark: isDark) : chrome.cardFill;
    final line =
        highlighted
            ? accentColor
            : (mine
                ? accentColor.withValues(alpha: isDark ? 0.28 : 0.18)
                : chrome.line);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: TokensStrip.s1),
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s3,
            TokensStrip.s3,
            TokensStrip.s3,
            TokensStrip.s2,
          ),
          constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
            border: Border.all(color: line, width: highlighted ? 1.6 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!deleted && msg.replyToMessageId != null)
                ConversationReplySnippet(
                  isDark: isDark,
                  accentColor: accentColor,
                  sender: replyLabelBuilder(msg.replyToRemetente ?? ''),
                  preview:
                      msg.replyToConteudo?.trim().isNotEmpty == true
                          ? msg.replyToConteudo!.trim()
                          : 'Mídia',
                  onTap: onReplyTap,
                ),
              if (!deleted)
                ConversationMediaPreview(
                  msg: msg,
                  mine: mine,
                  isDark: isDark,
                  onOpen: onOpenMedia,
                ),
              if (deleted)
                Text(
                  'Mensagem apagada',
                  style: FocuxHubTypography.body(
                    color: textColor.withValues(alpha: 0.72),
                  ).copyWith(fontStyle: FontStyle.italic),
                )
              else if (displayText.isNotEmpty &&
                  !_isMediaLabelOnly(msg.primaryMediaType, msg.conteudo))
                Text(
                  displayText,
                  style: FocuxHubTypography.body(color: textColor).copyWith(
                    height: TokensStrip.leadingBody,
                    letterSpacing: 0.2,
                  ),
                ),
              if (msg.reactions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final reaction in msg.reactions)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              reaction.mine
                                  ? accentColor.withValues(alpha: 0.14)
                                  : chrome.sheetFill,
                          borderRadius: BorderRadius.circular(TokensStrip.rPill),
                          border: Border.all(
                            color:
                                reaction.mine
                                    ? accentColor.withValues(alpha: 0.4)
                                    : chrome.line,
                          ),
                        ),
                        child: Text(
                          '${reaction.emoji} ${reaction.total}',
                          style: FocuxHubTypography.chip(textColor),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!deleted && msg.editedAt != null) ...[
                    Text(
                      'editada',
                      style: FocuxHubTypography.chip(metaColor),
                    ),
                    const SizedBox(width: TokensStrip.s1),
                  ],
                  Text(
                    _conversationTimeLabel(msg.enviadoEm),
                    style: FocuxHubTypography.chip(metaColor),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 6),
                    ConversationDeliveryStatus(msg: msg, color: metaColor),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isMediaLabelOnly(String? tipoMidia, String conteudo) {
    if (tipoMidia == null) return false;
    return ['IMAGE', 'IMAGEM', 'VIDEO', 'AUDIO'].contains(tipoMidia);
  }

}

String _conversationTimeLabel(DateTime dt) {
  final local = dt.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class ConversationReplySnippet extends StatelessWidget {
  final bool isDark;
  final Color accentColor;
  final String sender;
  final String preview;
  final VoidCallback? onTap;

  const ConversationReplySnippet({
    super.key,
    required this.isDark,
    required this.accentColor,
    required this.sender,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: TokensStrip.s2),
        padding: const EdgeInsets.symmetric(
          horizontal: TokensStrip.s3,
          vertical: TokensStrip.s2,
        ),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: isDark ? 0.16 : 0.08),
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sender, style: FocuxHubTypography.chip(accentColor)),
            const SizedBox(height: 2),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          ],
        ),
      ),
    );
  }
}
