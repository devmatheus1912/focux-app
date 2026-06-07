import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
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
  });

  final String title;
  final String action;
  final String reason;
  final Color color;
  final String? fullAction;
  final bool isIaSuggestion;
  final VoidCallback? onPrepareMessage;

  @override
  State<Aluno360CopilotPrescription> createState() =>
      _Aluno360CopilotPrescriptionState();
}

class _Aluno360CopilotPrescriptionState
    extends State<Aluno360CopilotPrescription> {
  static const _collapsedLines = 3;
  bool _expandedAction = false;
  bool _expandedReason = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final caption = isDark ? EagleTokens.darkInkMute : const Color(0xFF475569);
    final reason = widget.reason.trim();
    final expandedActionText = widget.fullAction ?? widget.action;
    final showExpandAction =
        expandedActionText.trim() != widget.action.trim() ||
        expandedActionText.trim().length > 72;
    final showExpandReason = reason.length > 72;

    return Semantics(
      label:
          '${widget.title}. ${expandedActionText}. $reason'
          '${showExpandAction && !_expandedAction ? '. Toque para ver ação completa' : ''}'
          '${showExpandReason && !_expandedReason ? '. Toque para ver contexto completo' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: widget.color, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap:
                showExpandAction
                    ? () => setState(() => _expandedAction = !_expandedAction)
                    : null,
            behavior: HitTestBehavior.opaque,
            child: Text(
              _expandedAction ? expandedActionText : widget.action,
              maxLines: _expandedAction ? null : 2,
              overflow: _expandedAction ? null : TextOverflow.ellipsis,
              style: AppTypography.inter(
                color: ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                height: 1.38,
              ),
            ),
          ),
          if (showExpandAction && !_expandedAction)
            Semantics(
              button: true,
              label: 'Ver ação completa da sugestão',
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Ver ação completa',
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                    decorationColor: widget.color.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          if (widget.onPrepareMessage != null) ...[
            const SizedBox(height: 12),
            Semantics(
              button: true,
              label: 'Preparar mensagem para o aluno',
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: widget.onPrepareMessage,
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 17,
                    color: widget.color,
                  ),
                  label: Text(
                    'Preparar mensagem',
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    elevation: 0,
                    foregroundColor: widget.color,
                    backgroundColor: widget.color.withValues(alpha: 0.10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap:
                  showExpandReason
                      ? () => setState(() => _expandedReason = !_expandedReason)
                      : null,
              behavior: HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.insights_outlined, size: 14, color: caption),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reason,
                      maxLines: _expandedReason ? null : _collapsedLines,
                      overflow: _expandedReason ? null : TextOverflow.ellipsis,
                      style: TextStyle(
                        color: caption,
                        fontSize: 12,
                        height: 1.32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showExpandReason && !_expandedReason)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 20),
                child: Text(
                  'Ver contexto',
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ],
      ),
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
    this.onPrepareMessage,
    this.preferContactPriority = false,
    this.wearableRelevant = true,
    this.contactPriority = false,
  });

  final Aluno aluno;
  final Color primary;
  final String fallback;
  final Map<String, dynamic>? seed360;
  final bool forceIa;
  final AsyncValue<Map<String, dynamic>>? iaAsync;
  final bool resumoLoading;
  final VoidCallback? onPrepareMessage;
  final bool preferContactPriority;
  final bool wearableRelevant;
  final bool contactPriority;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = ShellChrome.of(context).line;
    final isIaLoading = forceIa && (iaAsync?.isLoading ?? false);
    final isIaData = forceIa && (iaAsync?.hasValue ?? false);

    late final Widget child;
    if (forceIa && iaAsync != null) {
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
              ),
              isIaSuggestion: true,
            ),
      );
    } else if (seed360 != null) {
      final seedAcao = (seed360!['acao'] ?? '').toString();
      final useContactPriority =
          preferContactPriority && !forceIa && !acaoSugereChat(seedAcao);
      child = _fromContent(
        useContactPriority
            ? contactPriorityPrescriptionContent(aluno)
            : resolveCopilotPrescriptionFromAction(
              aluno,
              seed360!,
              fallback,
              wearableRelevant: wearableRelevant,
              contactPriority: contactPriority,
            ),
      );
    } else if (resumoLoading) {
      child = Aluno360CopilotPrescriptionLoading(color: primary);
    } else {
      child = _fromContent(offlineCopilotPrescription(fallback));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.04)
                : BrandPalette.softer(primary),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isIaData ? primary.withValues(alpha: 0.28) : line,
        ),
        boxShadow:
            isIaData
                ? [
                  BoxShadow(
                    color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
                : null,
      ),
      foregroundDecoration:
          isIaData || isIaLoading
              ? BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border(
                  left: BorderSide(
                    color: primary.withValues(alpha: 0.85),
                    width: 3,
                  ),
                ),
              )
              : null,
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
    );
  }
}
