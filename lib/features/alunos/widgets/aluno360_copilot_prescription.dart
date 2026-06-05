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
  });

  final String title;
  final String action;
  final String reason;
  final Color color;

  @override
  State<Aluno360CopilotPrescription> createState() =>
      _Aluno360CopilotPrescriptionState();
}

class _Aluno360CopilotPrescriptionState
    extends State<Aluno360CopilotPrescription> {
  static const _collapsedLines = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final caption = isDark ? EagleTokens.darkInkMute : const Color(0xFF374151);
    final reason = widget.reason.trim();
    final showExpand = reason.length > 72;

    return Semantics(
      label:
          '${widget.title}. ${widget.action}. $reason'
          '${showExpand && !_expanded ? '. Toque para ver texto completo' : ''}',
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
            ],
          ),
          const SizedBox(height: 7),
          Text(
            widget.action,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.28,
            ),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 5),
            GestureDetector(
              onTap:
                  showExpand
                      ? () => setState(() => _expanded = !_expanded)
                      : null,
              behavior: HitTestBehavior.opaque,
              child: Text(
                reason,
                maxLines: _expanded ? null : _collapsedLines,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: TextStyle(color: caption, fontSize: 12, height: 1.25),
              ),
            ),
            if (showExpand && !_expanded)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Ver mais',
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
            ),
        data:
            (action) => _fromContent(
              resolveCopilotPrescriptionFromAction(aluno, action, fallback),
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

  Widget _fromContent(CopilotPrescriptionContent content) {
    return Aluno360CopilotPrescription(
      title: content.title,
      action: content.action,
      reason: content.reason,
      color: primary,
    );
  }
}
