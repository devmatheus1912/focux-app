import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/data/health_repository.dart';
import '../data/aluno_repository.dart';
import '../constants/aluno_360_layout.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/aluno360_copilot_logic.dart';
import '../utils/aluno360_operacao_logic.dart';
import '../utils/ficha_operacao_card.dart';
import 'aluno360_copilot_card.dart';
import 'aluno360_finance_risk_banner.dart';
import 'aluno360_follow_up_card.dart';
import 'aluno360_operacao_sticky_cta.dart';
import 'aluno360_operacao_tab.dart';
import 'aluno360_operational_status_section.dart';
import 'aluno360_recovery_insight_card.dart';
import 'aluno360_student_quick_actions.dart';
import 'ficha_operacao_card_view.dart';
import '../../treinos/screens/aluno_rotina_screen.dart';

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
    this.aderenciaBundle,
    required this.recoveryAsync,
    required this.autonomiaResumoAsync,
    required this.animateEntrance,
    required this.onEntrancePlayed,
    required this.onPassword,
    required this.onEdit,
    required this.onEvolve,
    this.onLista,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color primary;
  final ProximaAcaoResumo? proximaAcao360;
  final bool hasOpenCopilotTask360;
  final List<Map<String, dynamic>>? aderenciaSemanal;
  final AderenciaSemanalBundle? aderenciaBundle;
  final AsyncValue<RecoverySnapshot?> recoveryAsync;
  final AsyncValue<AlunoAutonomiaResumo> autonomiaResumoAsync;
  final bool animateEntrance;
  final VoidCallback onEntrancePlayed;
  final VoidCallback onPassword;
  final VoidCallback onEdit;
  final VoidCallback onEvolve;
  final VoidCallback? onLista;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeRisk =
        aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente;
    final operacaoSnapshot = ref.watch(aluno360OperacaoProvider(alunoId));
    final contactPriority = operacaoSnapshot?.contactPriority ?? false;
    final showRecovery = alunoTemHistoricoWearable(recoveryAsync.value);
    final carregando = ref.watch(alunoCopilotCreatingProvider(alunoId));
    final card =
        operacaoSnapshot == null
            ? null
            : fichaOperacaoCard(
              sticky: operacaoSnapshot.stickyAction,
              textoProximaAcao: operacaoSnapshot.effectiveProxima?.acao,
            );

    void abrirFicha() {
      showFichaOperacaoPainel(
        context,
        child: Aluno360OperacaoTab(
          alunoId: alunoId,
          showFinanceRisk: financeRisk,
          animateEntrance: false,
          onEntrancePlayed: onEntrancePlayed,
          financeRiskBanner:
              financeRisk ? Aluno360FinanceRiskBanner(alunoId: alunoId) : null,
          showFollowUp: true,
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
            aderenciaBundle: aderenciaBundle,
          ),
          copilotCard: Aluno360CopilotCard(
            aluno: aluno,
            alunoId: alunoId,
            resumoAsync: autonomiaResumoAsync,
            proximaAcao360: proximaAcao360,
            hasOpenCopilotTask360: hasOpenCopilotTask360,
            isDark: isDark,
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
            onPassword: onPassword,
            onEdit: onEdit,
            onEvolve: onEvolve,
            onLista: onLista,
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: 'Conteúdo da aba operação',
      child: Aluno360Layout.operacaoContentWidthLimiter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (card != null) ...[
              FichaOperacaoCardView(
                card: card,
                carregando: carregando,
                onAction:
                    () => abrirOperacaoSticky(
                      context: context,
                      aluno: aluno,
                      alunoId: alunoId,
                      sticky: operacaoSnapshot!.stickyAction,
                      proxima: operacaoSnapshot.effectiveProxima,
                      outreach: operacaoSnapshot.outreachMessage,
                    ),
              ),
              const SizedBox(height: Aluno360Layout.sectionGap),
            ],
            AlunoRotinaLinha(alunoId: alunoId, alunoNome: aluno.nome),
            FichaOperacaoVerFichaButton(onPressed: abrirFicha),
          ],
        ),
      ),
    );
  }
}
