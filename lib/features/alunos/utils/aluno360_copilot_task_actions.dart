import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../ia/data/ia_repository.dart';
import '../utils/aluno360_operacao_logic.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';

/// Tela de Tarefas do Copiloto.
const tarefasCopilotoRota = '/dashboard/command-center/copiloto';

/// Creates or surfaces an open Copilot task in Command Center from Aluno 360.
Future<bool> criarTarefaCopilotoFromAluno360({
  required BuildContext context,
  required WidgetRef ref,
  required Aluno aluno,
  required String acao,
}) async {
  try {
    final existing = findOpenCopilotTask(
      await ref
          .read(dashboardRepositoryProvider)
          .getIaCommandActions(status: 'ABERTO', alunoId: aluno.id),
    );
    if (existing != null) {
      ref.invalidate(alunoOpenIaActionsProvider(aluno.id));
      if (context.mounted) {
        final nome = aluno.nome.trim().split(RegExp(r'\s+')).first;
        final router = GoRouter.of(context);
        FeedbackHelper.showSuccessAction(
          context,
          'Já existe uma tarefa para $nome.',
          actionLabel: 'Ver',
          onAction: () => router.push(tarefasCopilotoRota),
        );
      }
      return true;
    }

    final saved = await IaRepository(
      ref.read(apiClientProvider),
    ).salvarAcaoCopiloto(
      alunoId: aluno.id,
      acao: acao,
      motivo:
          'Aluno 360: ação prescrita a partir de perfil, autonomia e risco.',
      modo: 'ALUNO_360',
      source: 'ALUNO_360',
      recommendationId:
          'ALUNO_360_${aluno.id}_${DateTime.now().millisecondsSinceEpoch}',
      createdFromInsight: true,
    );
    final actionKey = saved.actionKey ?? '';
    var persisted = saved.hasPersistedActionKey;
    if (persisted) {
      final abertas = await ref
          .read(dashboardRepositoryProvider)
          .getIaCommandActions(status: 'ABERTO', alunoId: aluno.id);
      persisted = abertas.any((item) => item.actionKey == actionKey);
    }
    invalidatePersonalDashboardHome(ref);
    ref.invalidate(commandCenterProvider);
    ref.invalidate(alunoOpenIaActionsProvider(aluno.id));
    if (context.mounted) {
      FeedbackHelper.showSuccess(
        context,
        persisted
            ? 'Tarefa criada em ${FocuxMicrocopy.commandCenter}.'
            : 'Servidor aceitou, mas a tarefa ainda não apareceu.',
      );
    }
    return persisted;
  } catch (e) {
    if (context.mounted) {
      FeedbackHelper.showError(
        context,
        'Não foi possível criar tarefa: ${friendlyError(e)}',
      );
    }
    return false;
  }
}
