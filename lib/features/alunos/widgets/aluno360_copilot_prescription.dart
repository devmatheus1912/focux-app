import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_copilot_logic.dart';

/// Collapsible IA / 360 prescription block inside the copilot card.
class Aluno360CopilotPrescription extends StatefulWidget {
  const Aluno360CopilotPrescription({
    super.key,
    required this.title,
    required this.action,
    required this.reason,
    required this.color,
    this.fullAction,
    this.isIaSuggestion = false,
    this.onPrepareMessage,
    this.showTitle = true,
  });

  final String title;
  final String action;
  final String reason;
  final Color color;
  final String? fullAction;
  final bool isIaSuggestion;
  final VoidCallback? onPrepareMessage;
  final bool showTitle;

  @override
  State<Aluno360CopilotPrescription> createState() =>
      _Aluno360CopilotPrescriptionState();
}

class _Aluno360CopilotPrescriptionState
    extends State<Aluno360CopilotPrescription> {
  static const _collapsedLines = 2;
  bool _expandedAction = false;
  bool _expandedReason = false;
  bool _actionTruncated = false;
  String? _lastOverflowText;
  double? _lastOverflowWidth;

  TextStyle _actionStyle(Color ink) =>
      Aluno360Layout.bodyEmphasisStyle(context, ink);

  void _scheduleActionOverflowCheck({
    required String text,
    required double maxWidth,
    required TextStyle style,
  }) {
    if (_lastOverflowText == text && _lastOverflowWidth == maxWidth) return;
    _lastOverflowText = text;
    _lastOverflowWidth = maxWidth;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: _collapsedLines,
        textDirection: Directionality.of(context),
      )..layout(maxWidth: maxWidth);
      final truncated = painter.didExceedMaxLines;
      if (truncated != _actionTruncated && mounted) {
        setState(() => _actionTruncated = truncated);
      }
    });
  }

  void _toggleExpandedReason() {
    setState(() => _expandedReason = !_expandedReason);
  }

  void _toggleExpandedAction() {
    setState(() => _expandedAction = !_expandedAction);
  }

  TextStyle _expandLinkStyle({required bool active}) {
    return Aluno360Layout.captionStyle(context).copyWith(
      color: widget.color.withValues(alpha: active ? 0.92 : 0.68),
      fontWeight: FontWeight.w700,
      decoration: active ? TextDecoration.underline : TextDecoration.none,
      decorationColor: widget.color.withValues(alpha: 0.45),
    );
  }

  Widget _buildExpandLink({
    required String label,
    required String semanticsLabel,
    required VoidCallback onTap,
    required bool active,
    EdgeInsets padding = const EdgeInsets.only(top: 4),
  }) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: padding,
            child: Text(label, style: _expandLinkStyle(active: active)),
          ),
        ),
      ),
    );
  }

  Widget _buildReasonFooter({
    required String reason,
    required Color caption,
    required double maxWidth,
    required bool showExpandReason,
  }) {
    final segments = copilotPrescriptionReasonSegments(reason);
    final stackSegments = maxWidth < 340 && segments.length > 1;

    Widget reasonBody;
    if (stackSegments && !_expandedReason) {
      reasonBody = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < segments.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: Aluno360Layout.metaStyle(context).copyWith(
                      color: caption.withValues(alpha: 0.72),
                      height: 1.32,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      segments[i],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Aluno360Layout.captionStyle(context).copyWith(
                        color: caption,
                        height: 1.32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    } else {
      reasonBody = Text(
        reason,
        maxLines: _expandedReason ? null : _collapsedLines,
        overflow: _expandedReason ? null : TextOverflow.ellipsis,
        style: Aluno360Layout.captionStyle(context).copyWith(
          color: caption,
          height: 1.32,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: showExpandReason ? _toggleExpandedReason : null,
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.insights_outlined, size: 14, color: caption),
              const SizedBox(width: 6),
              Expanded(child: reasonBody),
            ],
          ),
        ),
        if (showExpandReason && !_expandedReason)
          _buildExpandLink(
            label: 'Ver contexto',
            semanticsLabel: 'Ver contexto completo da sugestão',
            onTap: _toggleExpandedReason,
            active: false,
            padding: const EdgeInsets.only(top: 4, left: 20),
          ),
        if (showExpandReason && _expandedReason)
          _buildExpandLink(
            label: 'Ocultar',
            semanticsLabel: 'Ocultar contexto da sugestão',
            onTap: _toggleExpandedReason,
            active: true,
            padding: const EdgeInsets.only(top: 4, left: 20),
          ),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant Aluno360CopilotPrescription oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.action != widget.action) {
      _actionTruncated = false;
      _lastOverflowText = null;
      _lastOverflowWidth = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final caption = isDark ? EagleTokens.darkInkMute : const Color(0xFF475569);
    final reason = widget.reason.trim();
    final expandedActionText = widget.fullAction ?? widget.action;
    final hasDistinctFullAction =
        widget.fullAction != null &&
        widget.fullAction!.trim().isNotEmpty &&
        !copilotPrescriptionActionsEquivalent(
          widget.fullAction!,
          widget.action,
        );
    final actionStyle = _actionStyle(ink);
    final showExpandReason = reason.length > 72;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_expandedAction) {
          _scheduleActionOverflowCheck(
            text: widget.action,
            maxWidth: constraints.maxWidth,
            style: actionStyle,
          );
        }
        final showExpandAction = hasDistinctFullAction || _actionTruncated;

        return Semantics(
          label:
              '${widget.showTitle ? '${widget.title}. ' : ''}$expandedActionText. $reason'
              '${showExpandAction && !_expandedAction ? '. Toque para ver ação completa' : ''}'
              '${showExpandReason && !_expandedReason ? '. Toque para ver contexto completo' : ''}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showTitle) ...[
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: widget.color, size: 17),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Aluno360Layout.chipLabelStyle(
                          context,
                          color: ink,
                        ).copyWith(letterSpacing: 0.2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              GestureDetector(
                onTap: showExpandAction ? _toggleExpandedAction : null,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  _expandedAction ? expandedActionText : widget.action,
                  maxLines: _expandedAction ? null : _collapsedLines,
                  overflow: _expandedAction ? null : TextOverflow.ellipsis,
                  style: actionStyle,
                ),
              ),
              if (showExpandAction && !_expandedAction)
                _buildExpandLink(
                  label: 'Ver ação completa',
                  semanticsLabel: 'Ver ação completa da sugestão',
                  onTap: _toggleExpandedAction,
                  active: false,
                ),
              if (showExpandAction && _expandedAction)
                _buildExpandLink(
                  label: 'Ocultar',
                  semanticsLabel: 'Ocultar ação completa da sugestão',
                  onTap: _toggleExpandedAction,
                  active: true,
                ),
              if (widget.onPrepareMessage != null) ...[
            SizedBox(height: showExpandAction ? 16 : 12),
            Semantics(
              button: true,
              label: 'Preparar mensagem para o aluno',
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: widget.onPrepareMessage,
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 17,
                  ),
                  label: const Text('Preparar mensagem'),
                  style: Aluno360Layout.operacaoOutlinedButtonStyle(
                    context,
                    widget.color,
                  ).copyWith(
                    textStyle: WidgetStateProperty.all(
                      Aluno360Layout.chipLabelStyle(context).copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Aluno360Layout.operacaoOutlinedForeground(
                          widget.color,
                          isDark:
                              Theme.of(context).brightness == Brightness.dark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildReasonFooter(
              reason: reason,
              caption: caption,
              maxWidth: constraints.maxWidth,
              showExpandReason: showExpandReason,
            ),
          ],
            ],
          ),
        );
      },
    );
  }
}

class Aluno360CopilotPrescriptionLoading extends StatelessWidget {
  const Aluno360CopilotPrescriptionLoading({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : color.withValues(alpha: 0.12);
    final highlight =
        isDark
            ? Colors.white.withValues(alpha: 0.22)
            : color.withValues(alpha: 0.28);

    Widget bone(double w, double h, {double radius = 8}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return Semantics(
      label: 'Carregando sugestão do Copiloto',
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                bone(17, 17, radius: 4),
                const SizedBox(width: 7),
                Expanded(child: bone(double.infinity, 12, radius: 6)),
              ],
            ),
            const SizedBox(height: 10),
            bone(double.infinity, 14, radius: 6),
            const SizedBox(height: 6),
            bone(220, 14, radius: 6),
            const SizedBox(height: 8),
            bone(180, 11, radius: 6),
          ],
        ),
      ),
    );
  }
}

/// Resolves prescription source (IA, 360 seed, offline) and renders the body.
class Aluno360CopilotPrescriptionBody extends StatelessWidget {
  const Aluno360CopilotPrescriptionBody({
    super.key,
    required this.aluno,
    required this.primary,
    required this.fallback,
    required this.seed360,
    required this.forceIa,
    required this.iaAsync,
    required this.resumoLoading,
    this.iaRefreshing = false,
    this.onPrepareMessage,
    this.preferContactPriority = false,
    this.wearableRelevant = true,
    this.contactPriority = false,
    this.statusMetricsVisible = false,
    this.hideMetricFooter = false,
  });

  final Aluno aluno;
  final Color primary;
  final String fallback;
  final Map<String, dynamic>? seed360;
  final bool forceIa;
  final AsyncValue<Map<String, dynamic>>? iaAsync;
  final bool resumoLoading;
  final bool iaRefreshing;
  final VoidCallback? onPrepareMessage;
  final bool preferContactPriority;
  final bool wearableRelevant;
  final bool contactPriority;
  final bool statusMetricsVisible;
  final bool hideMetricFooter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIaLoading =
        iaRefreshing || (forceIa && (iaAsync?.isLoading ?? false));
    final isIaData = forceIa && (iaAsync?.hasValue ?? false);

    late final Widget child;
    if (forceIa && iaAsync != null) {
      if (isIaLoading && !isIaData) {
        child = Aluno360CopilotPrescriptionLoading(color: primary);
      } else if (isIaLoading && isIaData) {
        child = Stack(
          children: [
            Opacity(
              opacity: 0.45,
              child: _fromContent(
                resolveCopilotPrescriptionFromAction(
                  aluno,
                  copilotActionFromIa(iaAsync!.value!),
                  fallback,
                  wearableRelevant: wearableRelevant,
                  contactPriority: contactPriority,
                  statusMetricsVisible: statusMetricsVisible,
                  hideMetricFooter: hideMetricFooter,
                ),
                isIaSuggestion: true,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Aluno360CopilotPrescriptionLoading(color: primary),
              ),
            ),
          ],
        );
      } else {
        child = iaAsync!.when(
          loading: () => Aluno360CopilotPrescriptionLoading(color: primary),
          error:
              (_, __) => _fromContent(
                iaErrorCopilotPrescription(fallback),
                isIaSuggestion: false,
              ),
          data:
              (action) => _fromContent(
                resolveCopilotPrescriptionFromAction(
                  aluno,
                  copilotActionFromIa(action),
                  fallback,
                  wearableRelevant: wearableRelevant,
                  contactPriority: contactPriority,
                  statusMetricsVisible: statusMetricsVisible,
                  hideMetricFooter: hideMetricFooter,
                ),
                isIaSuggestion: true,
              ),
        );
      }
    } else if (seed360 != null) {
      final seedAcao = (seed360!['acao'] ?? '').toString();
      final useContactPriority =
          preferContactPriority && !forceIa && !acaoSugereChat(seedAcao);
      child = _fromContent(
        useContactPriority
            ? contactPriorityPrescriptionContent(
              aluno,
              statusMetricsVisible: statusMetricsVisible,
              hideMetricFooter: hideMetricFooter,
            )
            : resolveCopilotPrescriptionFromAction(
              aluno,
              seed360!,
              fallback,
              wearableRelevant: wearableRelevant,
              contactPriority: contactPriority,
              statusMetricsVisible: statusMetricsVisible,
              hideMetricFooter: hideMetricFooter,
            ),
      );
    } else if (resumoLoading) {
      child = Aluno360CopilotPrescriptionLoading(color: primary);
    } else {
      child = _fromContent(offlineCopilotPrescription(fallback));
    }

    final iaAccent = isIaData || isIaLoading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: Aluno360Layout.operacaoPrescriptionDecoration(
        context,
        primary: primary,
        isDark: isDark,
        iaAccent: iaAccent,
      ),
      child: child,
    );
  }

  Widget _fromContent(
    CopilotPrescriptionContent content, {
    bool isIaSuggestion = false,
  }) {
    return Aluno360CopilotPrescription(
      title: content.title,
      action: content.action,
      fullAction: content.fullAction,
      reason: content.reason,
      color: primary,
      isIaSuggestion: isIaSuggestion,
      onPrepareMessage: onPrepareMessage,
      showTitle: !contactPriority,
    );
  }
}
