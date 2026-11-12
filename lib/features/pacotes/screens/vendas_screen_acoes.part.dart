part of 'vendas_screen.dart';

extension _VendasAcoes on _VendasScreenState {
  Future<void> _editarPlano(Pacote? plano) async {
    HapticFeedback.selectionClick();
    final ok = await showPlanoSheet(
      context,
      repo: ref.read(pacoteRepositoryProvider),
      plano: plano,
    );
    if (!ok || !mounted) return;
    FeedbackHelper.showSuccess(
      context,
      plano == null
          ? pacoteCriadoMensagem(paginaNoAr: _paginaNoAr)
          : 'Plano salvo.',
    );
    await _carregar(force: true);
  }

  Future<void> _maisPlano(Pacote p) async {
    final acao = await showFxGroupedActionSheet<String>(
      context,
      titulo: p.titulo,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'destaque',
            rotulo: p.destaque ? 'Tirar o destaque' : 'Destacar na página',
            icone: FxIcons.estrela,
          ),
        ]),
      ],
      destrutiva: const FxActionItem(
        valor: 'excluir',
        rotulo: 'Tirar da página',
        icone: FxIcons.excluir,
      ),
      confirmarTitulo: 'Tirar o plano da página?',
      confirmarMensagem:
          'Ele some da sua página. Quem já comprou não é afetado.',
    );
    if (acao == null || !mounted) return;
    try {
      final repo = ref.read(pacoteRepositoryProvider);
      if (acao == 'destaque') {
        await repo.atualizar(p.id, destaque: !p.destaque);
      } else {
        await repo.desativar(p.id);
      }
      await _carregar(force: true);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _editarOferta(OfertaUpsell? oferta) async {
    HapticFeedback.selectionClick();
    final repo = ref.read(upsellRepositoryProvider);
    final ok = await showOfertaUpsellEditor(
      context,
      planos: _planos,
      existing: oferta,
      salvar: (d) async {
        try {
          if (oferta == null) {
            await repo.criar(
              titulo: d.titulo,
              descricao: d.descricao,
              valor: d.valor?.asReais,
              tipoGatilho: d.tipoGatilho,
              pacoteId: d.pacoteId,
            );
          } else {
            await repo.atualizar(
              id: oferta.id,
              titulo: d.pacoteId == null ? d.titulo : null,
              descricao: d.descricao,
              valor: d.pacoteId == null ? d.valor?.asReais : null,
              tipoGatilho: d.tipoGatilho,
              ativo: d.ativo,
              pacoteId: d.pacoteId,
            );
          }
          return null;
        } catch (e) {
          return friendlyError(e);
        }
      },
    );
    if (!ok || !mounted) return;
    FeedbackHelper.showSuccess(
      context,
      oferta == null ? 'Oferta criada' : 'Oferta salva',
    );
    await _carregar();
  }

  Future<void> _maisOferta(OfertaUpsell o) async {
    final acao = await showFxGroupedActionSheet<String>(
      context,
      titulo: o.titulo,
      grupos: [
        FxActionGroup<String>(null, [
          if (o.ativo)
            const FxActionItem(
              valor: 'enviar',
              rotulo: 'Enviar a um aluno',
              icone: FxIcons.enviar,
            ),
          FxActionItem(
            valor: 'ativo',
            rotulo: o.ativo ? 'Pausar' : 'Reativar',
            icone: o.ativo ? FxIcons.pausar : FxIcons.play,
          ),
        ]),
      ],
    );
    if (acao == null || !mounted) return;
    if (acao == 'enviar') return _enviarParaAluno(o);
    try {
      await ref
          .read(upsellRepositoryProvider)
          .atualizar(id: o.id, ativo: !o.ativo);
      await _carregar();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _enviarParaAluno(OfertaUpsell oferta) async {
    try {
      final home = await ref.read(alunosHomeProvider.future);
      if (!mounted) return;
      final alunos = filterAlunoPickerAlunos(home.alunos, '');
      if (alunos.isEmpty) {
        FeedbackHelper.showError(context, ofertaSemAlunos());
        return;
      }
      final alunoId = await showFxInsetPickerSheet<int>(
        context,
        title: ofertaEnviarPickerTitle(),
        items: [
          for (final a in alunos)
            FxInsetPickerSheetItem(
              value: a.id,
              label: fxTitleCaseName(a.nome),
              subtitle: a.email.trim().isEmpty ? null : a.email,
            ),
        ],
      );
      if (alunoId == null || !mounted) return;
      final aluno = alunos.where((a) => a.id == alunoId).firstOrNull;
      if (aluno == null) return;
      final ok = await showFxConfirmSheet(
        context,
        title: ofertaEnviarConfirmTitle(aluno.nome),
        message: ofertaEnviarConfirmMessage(oferta.titulo),
        icon: FxIcons.enviar,
        confirmLabel: 'Enviar',
      );
      if (!ok || !mounted) return;
      final envio = await ref
          .read(upsellRepositoryProvider)
          .enviar(ofertaId: oferta.id, alunoId: aluno.id);
      if (!mounted) return;
      FeedbackHelper.showSuccess(
        context,
        ofertaEnviarSuccess(pushEntregue: envio.pushEntregue),
      );
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Não enviamos a oferta'),
      );
    }
  }

  Future<void> _abrirPedido(LojaPedido pedido) async {
    final pix = lojaPedidoPix(pedido.pixCopiaECola);
    final pendente = lojaPedidoPendente(pedido.status);
    await showFxNoticeSheet(
      context,
      title: lojaPedidoLabel(
        buyerNome: pedido.buyerNome,
        buyerEmail: pedido.buyerEmail,
      ),
      icon: FxIcons.qrCode,
      message: '${vendasPedidoEstado(pedido)} · ${pedido.valor.format()}',
      extraActions: [
        if (pix != null)
          Padding(
            padding: const EdgeInsets.only(bottom: TokensStrip.s2),
            child: FxTonalButton(
              label: 'Copiar PIX',
              icon: FxIcons.copiar,
              expanded: true,
              onPressed: () async {
                await copySensitiveToClipboard(pix);
                if (!mounted) return;
                FeedbackHelper.showSuccess(context, 'Código copiado');
              },
            ),
          ),
        if (pendente)
          Padding(
            padding: const EdgeInsets.only(bottom: TokensStrip.s2),
            child: Builder(
              builder:
                  (sheetCtx) => FxTonalButton(
                    label: 'Confirmar pagamento',
                    expanded: true,
                    onPressed: () async {
                      Navigator.of(sheetCtx).pop();
                      await _confirmarPedido(pedido);
                    },
                  ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmarPedido(LojaPedido pedido) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Confirmar o pagamento deste PIX?',
      subtitle: lojaPedidoLabel(
        buyerNome: pedido.buyerNome,
        buyerEmail: pedido.buyerEmail,
      ),
      message: pedido.valor.format(),
      confirmLabel: 'Confirmar pagamento',
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(lojaRepositoryProvider).confirmar(pedido.id);
      await _carregar();
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Pagamento confirmado');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }
}
