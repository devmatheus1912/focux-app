import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/aluno360_copilot_logic.dart';
import '../utils/aluno360_copilot_task_actions.dart';
import 'aluno_outreach_message_sheet.dart';

/// Ações secundárias da Operação — atrás de um toque (v3.1 / A30).
class Aluno360StudentQuickActions extends ConsumerWidget {
  const Aluno360StudentQuickActions({
    super.key,
    required this.aluno,
    required this.onPassword,
    required this.onEdit,
    required this.onEvolve,
    this.onLista,
  });

  final Aluno aluno;
  final VoidCallback onPassword;
  final VoidCallback onEdit;
  final VoidCallback onEvolve;
  final VoidCallback? onLista;

  Future<void> _criarTarefa(BuildContext context, WidgetRef ref) async {
    final operacao = ref.read(aluno360OperacaoProvider(aluno.id));
    final fromProxima = operacao?.effectiveProxima?.acao.trim() ?? '';
    final acao =
        fromProxima.isNotEmpty
            ? fromProxima
            : copilotFallbackAction(aluno, null);
    ref.read(alunoCopilotCreatingProvider(aluno.id).notifier).state = true;
    try {
      await criarTarefaCopilotoFromAluno360(
        context: context,
        ref: ref,
        aluno: aluno,
        acao: acao,
      );
    } finally {
      ref.read(alunoCopilotCreatingProvider(aluno.id).notifier).state = false;
    }
  }

  void _abrirChat(BuildContext context, WidgetRef ref) {
    final operacao = ref.read(aluno360OperacaoProvider(aluno.id));
    final draft =
        operacao?.effectiveProxima?.mensagemSugerida?.trim() ??
        operacao?.outreachMessage.trim() ??
        '';
    if (draft.isNotEmpty) {
      showAlunoOutreachMessageSheet(
        context,
        alunoId: aluno.id,
        alunoNome: aluno.nome,
        message: draft,
        title: 'Mensagem sugerida',
        subtitle: 'Copiloto · revise antes de enviar.',
        icon: Icons.auto_awesome_rounded,
      );
      return;
    }
    context.push('/alunos/${aluno.id}/chat', extra: aluno.nome);
  }

  Future<void> _openMaisAcoes(BuildContext context, WidgetRef ref) async {
    final firstName = aluno.nome.split(' ').first;
    final items = <FxInsetPickerSheetItem<VoidCallback>>[
      if (onLista != null)
        FxInsetPickerSheetItem(
          value: onLista!,
          label: 'Lista de alunos',
          subtitle: 'Voltar para a lista',
          icon: Icons.list_alt_rounded,
        ),
      FxInsetPickerSheetItem(
        value: () => _criarTarefa(context, ref),
        label: 'Criar tarefa',
        subtitle: 'Abre no comando do dia',
        icon: Icons.playlist_add_check_rounded,
      ),
      FxInsetPickerSheetItem(
        value: () => _abrirChat(context, ref),
        label: 'Chat',
        subtitle: 'Mensagem ou conversa com $firstName',
        icon: Icons.chat_bubble_outline_rounded,
      ),
      FxInsetPickerSheetItem(
        value: onPassword,
        label: 'Senha de acesso',
        subtitle: 'Gerar ou reenviar para $firstName',
        icon: Icons.password_rounded,
      ),
      FxInsetPickerSheetItem(
        value: onEvolve,
        label: 'Evoluir com IA',
        subtitle: 'Sugestão de carga e progressão',
        icon: Icons.auto_awesome_outlined,
      ),
      FxInsetPickerSheetItem(
        value: onEdit,
        label: 'Editar cadastro',
        subtitle: 'Dados, contato e objetivo',
        icon: Icons.edit_outlined,
      ),
    ];
    final chosen = await showFxInsetPickerSheet<VoidCallback>(
      context,
      title: 'Mais ações',
      headerIcon: Icons.more_horiz_rounded,
      selected: null,
      items: items,
    );
    if (chosen == null) return;
    HapticFeedback.selectionClick();
    chosen();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstName = aluno.nome.split(' ').first;
    return Semantics(
      container: true,
      label: 'Mais ações da operação para $firstName',
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => _openMaisAcoes(context, ref),
          style: Aluno360Layout.secondaryTextLinkStyle(context),
          child: const Text('Mais ações'),
        ),
      ),
    );
  }
}
