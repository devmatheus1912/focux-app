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
      icone: FxIcons.repetir,
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
      if (acao == RecorrenciaAcao.cancelar) await _perguntarMensalidadeGerada(item);
      await _load(reset: true);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  /// Ao encerrar: a mensalidade do próximo ciclo pode já ter sido gerada
  /// (5 dias antes do vencimento). Pergunta se cancela também.
  Future<void> _perguntarMensalidadeGerada(RecorrenciaAssinatura item) async {
    final repo = FinanceiroRepository(ref.read(apiClientProvider));
    Mensalidade? gerada;
    try {
      final page = await repo.listarPagina(
        alunoId: item.alunoId,
        size: 10,
        filtro: MensalidadeFiltro.abertas,
      );
      final hoje = DateTime.now();
      final dia = DateTime(hoje.year, hoje.month, hoje.day);
      gerada = page.mensalidades.where((m) {
        final v = DateTime.tryParse(m.vencimento ?? '');
        return m.status == 'PENDENTE' && v != null && !v.isBefore(dia);
      }).firstOrNull;
    } catch (_) {
      return;
    }
    if (gerada == null || !mounted) return;
    final venc = DateTime.parse(gerada.vencimento!);
    final cancelar = await showFxConfirmSheet(
      context,
      title: 'Cancelar a mensalidade gerada?',
      message:
          'A mensalidade de ${financeiroMesTitulo(venc.month, venc.year).toLowerCase()} '
          '(${gerada.valor.formatCobranca()}, vence ${dataCurta(venc)}) já foi gerada.',
      confirmLabel: 'Cancelar também',
      cancelLabel: 'Manter',
      destructive: true,
    );
    if (!cancelar || !mounted) return;
    try {
      await repo.cancelar(gerada.id);
      if (mounted) FeedbackHelper.showSuccess(context, 'Mensalidade cancelada.');
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }
}
