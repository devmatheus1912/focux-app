import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/aluno360_copilot_logic.dart';
import '../utils/aluno360_copilot_task_actions.dart';
import '../utils/aluno360_operacao_logic.dart';
import '../widgets/aluno_outreach_message_sheet.dart';

/// Chip flutuante — paridade Perfil/Home (`DashboardHomeActionChip`).
class Aluno360OperacaoStickyCtaBar extends ConsumerWidget {
  const Aluno360OperacaoStickyCtaBar({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.proximaAcao360,
    required this.hasOpenCopilotTask360,
    required this.isDark,
  });

  final Aluno aluno;
  final int alunoId;
  final ProximaAcaoResumo? proximaAcao360;
  final bool hasOpenCopilotTask360;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final creating = ref.watch(alunoCopilotCreatingProvider(alunoId));
    // Bundle/snapshot only — never sidecar GET /ia on Operação critical path.
    final operacao = ref.watch(aluno360OperacaoProvider(alunoId));
    if (operacao == null) {
      return const SizedBox.shrink();
    }
    final sticky = operacao.stickyAction;
    final effectiveProxima = operacao.effectiveProxima;
    final hasOpenTask = hasOpenCopilotTask360;
    final followUpDue = isAlunoFollowUpDue(aluno);

    void openOutreach() {
      showAlunoOutreachMessageSheet(
        context,
        alunoId: alunoId,
        alunoNome: aluno.nome,
        message: operacao.outreachMessage,
        title: 'Mensagem sugerida',
        subtitle: 'Copiloto · revise antes de enviar.',
        icon: Icons.auto_awesome_rounded,
      );
    }

    void openChat({String? acao}) {
      final actionText = acao?.trim() ?? effectiveProxima?.acao.trim() ?? '';
      if (sticky.isChatAction ||
          (actionText.isNotEmpty && acaoSugereChat(actionText))) {
        openOutreach();
        return;
      }
      context.push('/alunos/$alunoId/chat', extra: aluno.nome);
    }

    void openCommandCenter() {
      context.push('/dashboard/command-center/copiloto');
    }

    void openEvolucao() {
      context.push('/alunos/$alunoId/evolucao', extra: aluno.nome);
    }

    void openEditAluno() {
      context.push('/alunos/$alunoId/editar', extra: aluno);
    }

    void onPrimary() {
      HapticFeedback.lightImpact();
      switch (sticky.destination) {
        case OperacaoStickyDestination.chat:
          openChat(acao: effectiveProxima?.acao);
        case OperacaoStickyDestination.commandCenter:
          openCommandCenter();
        case OperacaoStickyDestination.evolucao:
          openEvolucao();
        case OperacaoStickyDestination.editAluno:
          openEditAluno();
        case OperacaoStickyDestination.financeiro:
          context.push('/financeiro?alunoId=$alunoId');
        case OperacaoStickyDestination.treino:
          context.push('/alunos/$alunoId/treinos-list', extra: aluno.nome);
      }
    }

    final showSecondaryCommandCenter = shouldShowStickySecondaryCommandCenter(
      sticky: sticky,
      hasOpenTask: hasOpenTask,
    );
    final showSecondaryChat = shouldShowStickySecondaryChat(
      sticky: sticky,
      hasOpenTask: hasOpenTask,
      followUpDue: followUpDue,
      proximaAcaoText: effectiveProxima?.acao,
    );
    // Sem floaters no card: Criar tarefa / Chat sobem para o sticky (#10).
    final showSecondaryCreateTask =
        !hasOpenTask &&
        !operacao.hideCopilotTaskRow &&
        (effectiveProxima?.acao.trim().isNotEmpty ?? false);
    final showSecondaryChatMais =
        showSecondaryChat ||
        (!hasOpenTask &&
            !operacao.hideCopilotChatRow &&
            !sticky.isChatAction);
    final stickyDisplayLabel = operacao.stickyDisplayLabel;

    Future<void> createTask() async {
      final acao = effectiveProxima?.acao.trim() ?? '';
      if (acao.isEmpty) return;
      HapticFeedback.lightImpact();
      ref.read(alunoCopilotCreatingProvider(alunoId).notifier).state = true;
      try {
        await criarTarefaCopilotoFromAluno360(
          context: context,
          ref: ref,
          aluno: aluno,
          acao: acao,
        );
      } finally {
        ref.read(alunoCopilotCreatingProvider(alunoId).notifier).state = false;
      }
    }

    return SafeArea(
      top: false,
      child: Semantics(
        container: true,
        label: 'Ações rápidas da aba operação',
        child: Padding(
          key: const ValueKey('aluno360_operacao_sticky_cta'),
          padding: EdgeInsets.fromLTRB(
            TokensStrip.s4,
            0,
            TokensStrip.s4,
            10 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showSecondaryCommandCenter ||
                  showSecondaryChatMais ||
                  showSecondaryCreateTask)
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensStrip.s2),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (showSecondaryCreateTask)
                        DashboardHomeActionChip(
                          label: 'Criar tarefa',
                          accent: primary,
                          isDark: isDark,
                          enabled: !creating,
                          onPressed: createTask,
                        ),
                      if (showSecondaryCommandCenter)
                        DashboardHomeActionChip(
                          label: 'Tarefa',
                          accent: primary,
                          isDark: isDark,
                          onPressed: openCommandCenter,
                        ),
                      if (showSecondaryChatMais)
                        DashboardHomeActionChip(
                          label: 'Chat',
                          accent: primary,
                          isDark: isDark,
                          onPressed: () => openChat(acao: effectiveProxima?.acao),
                        ),
                    ],
                  ),
                ),
              Semantics(
                button: true,
                label: stickyDisplayLabel,
                child: FxLiquidPrimaryButton(
                  label: stickyDisplayLabel,
                  loading: creating,
                  onPressed: creating ? null : onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
