import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/design_tokens.dart';
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
    this.isIaSuggestion = false,
  });

  final String title;
  final String action;
  final String reason;
  final Color color;
  final bool isIaSuggestion;

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
    final caption = isDark ? EagleTokens.darkInkMute : const Color(0xFF374151);
    final reason = widget.reason.trim();
    final showExpandAction = widget.action.trim().length > 72;
    final showExpandReason = reason.length > 72;

    return Semantics(
      label:
          '${widget.title}. ${widget.action}. $reason'
          '${showExpandAction && !_expandedAction ? '. Toque para ver ação completa' : ''}'
          '${showExpandReason && !_expandedReason ? '. Toque para ver contexto completo' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: widget.color, size: 17),
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
                  ),
                ),
              ),
              if (widget.isIaSuggestion)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'IA',
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          GestureDetector(
            onTap:
                showExpandAction
                    ? () => setState(() => _expandedAction = !_expandedAction)
                    : null,
            behavior: HitTestBehavior.opaque,
            child: Text(
              widget.action,
              maxLines: _expandedAction ? null : _collapsedLines,
              overflow: _expandedAction ? null : TextOverflow.ellipsis,
              style: TextStyle(
                color: ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.32,
              ),
            ),
          ),
          if (showExpandAction && !_expandedAction)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Ver ação completa',
                style: TextStyle(
                  color: widget.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap:
                  showExpandReason
                      ? () => setState(() => _expandedReason = !_expandedReason)
                      : null,
              behavior: HitTestBehavior.opaque,
              child: Text(
                reason,
                maxLines: _expandedReason ? null : _collapsedLines,
                overflow: _expandedReason ? null : TextOverflow.ellipsis,
                style: TextStyle(color: caption, fontSize: 12, height: 1.28),
              ),
            ),
            if (showExpandReason && !_expandedReason)
              Padding(
                padding: const EdgeInsets.only(top: 4),
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
  });

  final Aluno aluno;
  final Color primary;
  final String fallback;
  final Map<String, dynamic>? seed360;
  final bool forceIa;
  final AsyncValue<Map<String, dynamic>>? iaAsync;
  final bool resumoLoading;

  @override
  Widget build(BuildContext context) {
    if (forceIa && iaAsync != null) {
      return iaAsync!.when(
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
              ),
              isIaSuggestion: true,
            ),
      );
    }
    if (seed360 != null) {
      return _fromContent(
        resolveCopilotPrescriptionFromAction(aluno, seed360!, fallback),
      );
    }
    if (resumoLoading) {
      return Aluno360CopilotPrescriptionLoading(color: primary);
    }
    return _fromContent(offlineCopilotPrescription(fallback));
  }

  Widget _fromContent(
    CopilotPrescriptionContent content, {
    bool isIaSuggestion = false,
  }) {
    return Aluno360CopilotPrescription(
      title: content.title,
      action: content.action,
      reason: content.reason,
      color: primary,
      isIaSuggestion: isIaSuggestion,
    );
  }
}
