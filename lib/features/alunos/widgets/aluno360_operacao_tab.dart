import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_premium_entrance.dart';
import '../constants/aluno_360_layout.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/aluno360_operacao_logic.dart';

/// Staggered entrance wrapper for Operação sections.
class Aluno360OperacaoEntrance extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (!enabled || reduceMotionOf(context)) return child;
    WidgetsBinding.instance.addPostFrameCallback((_) => onPlayed?.call());
    return ClipRect(
      child: FxPremiumEntrance(delay: delay, child: child),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showFinanceRisk && financeRiskBanner != null) ...[
          section(0, financeRiskBanner!),
          const SizedBox(height: Aluno360Layout.sectionGap),
        ],
        section(1, followUpCard),
        const SizedBox(height: Aluno360Layout.sectionGap),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child:
              focusMode
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      section(3, copilotCard),
                    ],
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
    );
  }
}
