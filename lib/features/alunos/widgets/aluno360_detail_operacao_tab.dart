import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/data/health_repository.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/aluno360_copilot_logic.dart';
import '../utils/aluno360_operacao_logic.dart';
import 'aluno360_copilot_card.dart';
import 'aluno360_finance_risk_banner.dart';
import 'aluno360_follow_up_card.dart';
import 'aluno360_operacao_tab.dart';
import 'aluno360_operational_status_section.dart';
import 'aluno360_recovery_insight_card.dart';
import 'aluno360_student_quick_actions.dart';

class Aluno360DetailOperacaoTab extends ConsumerWidget {
  const Aluno360DetailOperacaoTab({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.primary,
    required this.proximaAcao360,
    required this.hasOpenCopilotTask360,
    required this.aderenciaSemanal,
    required this.recoveryAsync,
    required this.autonomiaResumoAsync,
    required this.animateEntrance,
    required this.onEntrancePlayed,
    required this.onPassword,
    required this.onEdit,
    required this.onEvolve,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color primary;
  final ProximaAcaoResumo? proximaAcao360;
  final bool hasOpenCopilotTask360;
  final List<Map<String, dynamic>>? aderenciaSemanal;
  final AsyncValue<RecoverySnapshot?> recoveryAsync;
  final AsyncValue<AlunoAutonomiaResumo> autonomiaResumoAsync;
  final bool animateEntrance;
  final VoidCallback onEntrancePlayed;
  final VoidCallback onPassword;
  final VoidCallback onEdit;
  final VoidCallback onEvolve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeRisk =
        aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente;
    final operacaoSnapshot = ref.watch(aluno360OperacaoProvider(alunoId));
    final contactPriority = operacaoSnapshot?.contactPriority ?? false;
    final showRecovery = alunoTemHistoricoWearable(recoveryAsync.valueOrNull);
    final focusMode = ref.watch(alunoOperacaoFocusModeProvider(alunoId));
    final hideFollowUp =
        operacaoSnapshot != null &&
        shouldHideFollowUpInFocusContactMode(
          focusMode: focusMode,
          contactPriority: contactPriority,
          sticky: operacaoSnapshot.stickyAction,
        );

    return Aluno360OperacaoTab(
      alunoId: alunoId,
      showFinanceRisk: financeRisk,
      animateEntrance: animateEntrance,
      onEntrancePlayed: onEntrancePlayed,
      financeRiskBanner:
          financeRisk
              ? Aluno360FinanceRiskBanner(alunoId: alunoId, isDark: isDark)
              : null,
      showFollowUp: !hideFollowUp,
      followUpCard: Aluno360FollowUpCard(
        aluno: aluno,
        isDark: isDark,
        compactContactPriority: shouldCompactFollowUpForContactPriority(
          contactPriority: contactPriority,
        ),
      ),
      operationalSection: Aluno360OperationalStatusSection(
        aluno: aluno,
        alunoId: alunoId,
        isDark: isDark,
        primary: primary,
        aderenciaSemanal: aderenciaSemanal,
      ),
      copilotCard: Aluno360CopilotCard(
        aluno: aluno,
        alunoId: alunoId,
        resumoAsync: autonomiaResumoAsync,
        proximaAcao360: proximaAcao360,
        hasOpenCopilotTask360: hasOpenCopilotTask360,
        isDark: isDark,
        showFocusToggle: true,
        focusMode: focusMode,
      ),
      recoveryCard:
          showRecovery
              ? Aluno360RecoveryInsightCard(
                recoveryAsync: recoveryAsync,
                isDark: isDark,
                primary: primary,
              )
              : null,
      quickActions: Aluno360StudentQuickActions(
        aluno: aluno,
        isDark: isDark,
        primary: primary,
        onPassword: onPassword,
        onEdit: onEdit,
        onEvolve: onEvolve,
      ),
    );
  }
}
