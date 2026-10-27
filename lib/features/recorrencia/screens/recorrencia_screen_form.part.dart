part of 'recorrencia_screen.dart';

extension on _RecorrenciaScreenState {
  Future<void> _criar() async {
    final s = S.of(context);
    // Sem chave PIX a recorrência não gera cobrança: avisa antes de abrir a folha.
    final perfil = ref.read(perfilProvider).value;
    if (perfil != null && (perfil.chavePix ?? '').trim().isEmpty) {
      final cadastrar = await showFxConfirmSheet(
        context,
        title: s.recorrenciaFaltaPixTitulo,
        message: s.recorrenciaFaltaPixTexto,
        confirmLabel: s.recorrenciaFaltaPixConfirma,
        cancelLabel: s.recorrenciaFaltaPixDepois,
      );
      if (cadastrar && mounted) context.push('/perfil/wallet');
      return;
    }
    final criou = await showRecorrenciaNovaFolha(context, ref);
    if (!criou || !mounted) return;
    FeedbackHelper.showSuccess(context, recorrenciaCriadaMensagem);
    await _load(reset: true);
  }

  Future<void> _abrirAcoes(RecorrenciaAssinatura item) async {
    final acoes = recorrenciaAcoesDisponiveis(item.status);
    if (acoes.isEmpty) return;
    FxActionItem<RecorrenciaAcao> linha(RecorrenciaAcao a) => FxActionItem(
      valor: a,
      rotulo: recorrenciaAcaoLabel(a),
      descricao: recorrenciaAcaoDescricao(a),
      icone: recorrenciaAcaoIcone(a),
    );
    final encerrar = acoes.contains(RecorrenciaAcao.cancelar);
    final acao = await showFxGroupedActionSheet<RecorrenciaAcao>(
      context,
      titulo: recorrenciaAlunoLabel(item.alunoNome),
      icone: Icons.repeat_rounded,
      grupos: [
        FxActionGroup<RecorrenciaAcao>(null, [
          for (final a in acoes)
            if (a != RecorrenciaAcao.cancelar) linha(a),
        ]),
      ],
      destrutiva: encerrar ? linha(RecorrenciaAcao.cancelar) : null,
      confirmarTitulo: 'Encerrar recorrência?',
      confirmarMensagem:
          'Novas mensalidades param de ser lançadas. As já lançadas continuam.',
    );
    if (acao == null || !mounted) return;
    try {
      await RecorrenciaRepository(
        ref.read(apiClientProvider),
      ).acaoPersonal(item.id, recorrenciaAcaoPath(acao));
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, recorrenciaAcaoFeito(acao));
      await _load(reset: true);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }
}
