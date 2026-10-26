import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/aluno_repository.dart';
import '../utils/aluno360_copilot_logic.dart';
import '../utils/aluno360_operacao_logic.dart';
import '../widgets/aluno360_commitment_sheet.dart';
import '../widgets/aluno_outreach_message_sheet.dart';

/// Abre o destino da ação "Agora" do Resumo (chat, financeiro, ficha, cadastro…).
void abrirOperacaoSticky({
  required BuildContext context,
  required Aluno aluno,
  required int alunoId,
  required OperacaoStickyAction sticky,
  required ProximaAcaoResumo? proxima,
  required String outreach,
}) {
  HapticFeedback.lightImpact();
  switch (sticky.destination) {
    case OperacaoStickyDestination.chat:
      final actionText = proxima?.acao.trim() ?? '';
      if (sticky.isChatAction ||
          (actionText.isNotEmpty && acaoSugereChat(actionText))) {
        showAlunoOutreachMessageSheet(
          context,
          alunoId: alunoId,
          alunoNome: aluno.nome,
          message: outreach,
          title: 'Mensagem sugerida',
          subtitle: 'Copiloto · revise antes de enviar.',
          icon: Icons.auto_awesome_rounded,
        );
        return;
      }
      context.push('/alunos/$alunoId/chat', extra: aluno.nome);
    case OperacaoStickyDestination.commandCenter:
      context.push('/dashboard/command-center/copiloto');
    case OperacaoStickyDestination.evolucao:
      context.push('/alunos/$alunoId/evolucao', extra: aluno.nome);
    case OperacaoStickyDestination.editAluno:
      context.push('/alunos/$alunoId/editar', extra: aluno);
    case OperacaoStickyDestination.financeiro:
      context.push('/financeiro?alunoId=$alunoId');
    case OperacaoStickyDestination.treino:
      context.push('/alunos/$alunoId/treinos-list', extra: aluno.nome);
    case OperacaoStickyDestination.commitment:
      showAluno360CommitmentSheet(
        context,
        aluno: aluno,
        kind: Aluno360CommitmentKind.sleep,
      );
  }
}
