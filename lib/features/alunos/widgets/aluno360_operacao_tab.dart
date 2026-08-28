import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_premium_entrance.dart';
import '../constants/aluno_360_layout.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/aluno360_operacao_logic.dart';

/// Staggered entrance wrapper for Operação sections.
class Aluno360OperacaoEntrance extends StatefulWidget {
  const Aluno360OperacaoEntrance({
    super.key,
    required this.enabled,
    required this.delay,
    required this.child,
    this.onPlayed,
  });

  final bool enabled;
  final Duration delay;
  final Widget child;
  final VoidCallback? onPlayed;

  @override
  State<Aluno360OperacaoEntrance> createState() =>
      _Aluno360OperacaoEntranceState();
}

class _Aluno360OperacaoEntranceState extends State<Aluno360OperacaoEntrance> {
  var _played = false;

  @override
  Widget build(BuildContext context) {
    if (!_played && widget.enabled && widget.onPlayed != null) {
      _played = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPlayed?.call();
      });
    }
    if (!widget.enabled || reduceMotionOf(context)) return widget.child;
    return ClipRect(
      child: FxPremiumEntrance(delay: widget.delay, child: widget.child),
    );
  }
}

/// Operação tab layout: follow-up → diagnostics (or focus copilot) → quick actions.
class Aluno360OperacaoTab extends ConsumerWidget {
  const Aluno360OperacaoTab({
    super.key,
    required this.alunoId,
    required this.showFinanceRisk,
    required this.followUpCard,
    required this.showFollowUp,
    required this.operationalSection,
    required this.copilotCard,
    required this.quickActions,
    required this.animateEntrance,
    required this.onEntrancePlayed,
    this.financeRiskBanner,
    this.recoveryCard,
  });

  final int alunoId;
  final bool showFinanceRisk;
  final Widget? financeRiskBanner;
  final Widget followUpCard;
  final bool showFollowUp;
  final Widget operationalSection;
  final Widget copilotCard;
  final Widget? recoveryCard;
  final Widget quickActions;
  final bool animateEntrance;
  final VoidCallback onEntrancePlayed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusMode = ref.watch(alunoOperacaoFocusModeProvider(alunoId));
    final operacaoSnapshot = ref.watch(aluno360OperacaoProvider(alunoId));
    final contactPriority = operacaoSnapshot?.contactPriority ?? false;

    Widget section(int step, Widget child) {
      return Aluno360OperacaoEntrance(
        enabled: animateEntrance && !contactPriority,
        delay: operacaoSectionDelay(
          financeRisk: showFinanceRisk,
          stepIndex: step,
          contactPriority: contactPriority,
        ),
        onPlayed: onEntrancePlayed,
        child: child,
      );
    }

    Widget diagnosticBody() {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= Aluno360Layout.operacaoTabletBreakpoint) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: operationalSection),
                const SizedBox(width: Aluno360Layout.sectionGap),
                Expanded(child: copilotCard),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              operationalSection,
              const SizedBox(height: Aluno360Layout.sectionGap),
              copilotCard,
            ],
          );
        },
      );
    }

    final motionMs = fxMotionDurationMs(context, normal: 200);

    return Semantics(
      container: true,
      label: 'Conteúdo da aba operação',
      child: Aluno360Layout.operacaoContentWidthLimiter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showFinanceRisk && financeRiskBanner != null) ...[
              section(0, financeRiskBanner!),
              const SizedBox(height: Aluno360Layout.sectionGap),
            ],
            if (showFollowUp) ...[
              section(1, followUpCard),
              const SizedBox(height: Aluno360Layout.sectionGap),
            ],
            AnimatedSize(
              duration: Duration(milliseconds: motionMs),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child:
                  focusMode
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [section(3, copilotCard)],
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          section(2, diagnosticBody()),
                          if (recoveryCard != null) ...[
                            const SizedBox(height: Aluno360Layout.sectionGap),
                            section(4, recoveryCard!),
                          ],
                          const SizedBox(height: Aluno360Layout.sectionGap),
                          section(5, quickActions),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
