import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../data/chat_repository.dart';
import '../data/chat_text_formatter.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  isDark ? EagleTokens.slate400 : TokensStrip.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child:
                loading
                    ? SizedBox(
                      width: 16,
                      height: 16,
                      child: FxLoading(strokeWidth: 2, color: primary),
                    )
                    : Text(
                      'Carregar mensagens antigas',
                      style: TextStyle(
                        color: primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
          ),
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
    final iconColor = read ? EagleTokens.chatRead : color;

    final label =
        read
            ? 'Lido'
            : delivered
            ? 'Entregue'
            : 'Enviado';
    return Tooltip(
      message: label,
      child: Icon(
        delivered ? Icons.done_all_rounded : Icons.check_rounded,
        size: 14,
        color: iconColor,
        semanticLabel: label,
      ),
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
    final bg = widget.isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg;
    final border =
        widget.isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(color: border),
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
  final bool isDark;
  final Color accentColor;

  const ConversationChatBackdrop({
    super.key,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              isDark
                  ? [
                    EagleTokens.darkBg,
                    EagleTokens.darkCard,
                    EagleTokens.darkCardHi,
                  ]
                  : [
                    EagleTokens.paperSubtle,
                    EagleTokens.paper,
                    EagleTokens.brandSofter,
                  ],
        ),
      ),
      child: CustomPaint(
        painter: ConversationChatBackdropPainter(
          isDark: isDark,
          accentColor: accentColor,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class ConversationChatBackdropPainter extends CustomPainter {
  final bool isDark;
  final Color accentColor;

  const ConversationChatBackdropPainter({
    required this.isDark,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint =
        Paint()
          ..color = accentColor.withValues(alpha: isDark ? 0.08 : 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 64);
    final softPaint =
        Paint()
          ..color = (isDark ? Colors.white : Colors.white).withValues(
            alpha: 0.22,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.18),
      118,
      glowPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.10, size.height * 0.82),
      100,
      glowPaint,
    );
    if (!isDark) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.52, size.height * 0.48),
          width: size.width * 0.85,
          height: size.height * 0.42,
        ),
        softPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ConversationChatBackdropPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.accentColor != accentColor;
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
    final textColor =
        mine
            ? Colors.white
            : (isDark ? EagleTokens.darkInk : TokensStrip.textPrimary);
    final metaColor =
        mine
            ? Colors.white.withValues(alpha: 0.75)
            : (isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary);
    final deleted = msg.deletedAt != null;
    final displayText = formatChatTextForDisplay(msg.conteudo);
    final bubbleMaxWidth = (MediaQuery.sizeOf(context).width - 56).clamp(
      220.0,
      520.0,
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
          decoration: BoxDecoration(
            gradient:
                mine
                    ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accentColor, BrandPalette.deep(accentColor)],
                    )
                    : null,
            color:
                mine
                    ? null
                    : (isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
            border: Border.all(
              color:
                  highlighted
                      ? accentColor
                      : mine
                      ? Colors.transparent
                      : (isDark
                          ? EagleTokens.darkLine
                          : TokensStrip.borderDefault),
              width: highlighted ? 1.6 : 1,
            ),
            boxShadow:
                highlighted
                    ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.16),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                    : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!deleted && msg.replyToMessageId != null)
                ConversationReplySnippet(
                  mine: mine,
                  isDark: isDark,
                  accentColor: accentColor,
                  sender: replyLabelBuilder(msg.replyToRemetente ?? ''),
                  preview:
                      msg.replyToConteudo?.trim().isNotEmpty == true
                          ? msg.replyToConteudo!.trim()
                          : 'Midia',
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
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.72),
                    fontSize: 14,
                    height: 1.35,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else if (displayText.isNotEmpty &&
                  !_isMediaLabelOnly(msg.primaryMediaType, msg.conteudo))
                Text(
                  displayText,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.35,
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
                                  ? (mine
                                      ? Colors.white.withValues(alpha: 0.18)
                                      : accentColor.withValues(alpha: 0.12))
                                  : (mine
                                      ? Colors.white.withValues(alpha: 0.10)
                                      : (isDark
                                          ? EagleTokens.darkBg
                                          : TokensStrip.pageBg)),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color:
                                reaction.mine
                                    ? accentColor.withValues(alpha: 0.5)
                                    : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          '${reaction.emoji} ${reaction.total}',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight:
                                reaction.mine
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                          ),
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
                      style: TextStyle(color: metaColor, fontSize: 11),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    _timeLabel(msg.enviadoEm),
                    style: TextStyle(color: metaColor, fontSize: 11),
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

  String _timeLabel(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class ConversationReplySnippet extends StatelessWidget {
  final bool mine;
  final bool isDark;
  final Color accentColor;
  final String sender;
  final String preview;
  final VoidCallback? onTap;

  const ConversationReplySnippet({
    super.key,
    required this.mine,
    required this.isDark,
    required this.accentColor,
    required this.sender,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        mine
            ? Colors.white
            : (isDark ? EagleTokens.darkInk : TokensStrip.textPrimary);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color:
              mine
                  ? Colors.white.withValues(alpha: 0.14)
                  : accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sender,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.88),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.82),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
