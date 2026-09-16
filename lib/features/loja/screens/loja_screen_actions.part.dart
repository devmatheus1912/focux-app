part of 'loja_screen.dart';

extension on _LojaScreenState {
  Future<void> _checkoutPacote(Pacote pacote) async {
    final emailCtrl = TextEditingController();
    final nomeCtrl = TextEditingController();
    final ok = await showFxFormSheet(
      context,
      title: 'Checkout — ${pacote.titulo}',
      subtitle: formatBrlCurrency(pacote.valor),
      icon: Icons.qr_code_rounded,
      confirmLabel: 'Gerar PIX',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AlunoInsetFormField(
            controller: emailCtrl,
            label: 'Email do comprador',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          AlunoInsetFormField(
            controller: nomeCtrl,
            label: 'Nome (opcional)',
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            showDivider: false,
          ),
        ],
      ),
    );

    final email = emailCtrl.text.trim();
    final nome = nomeCtrl.text.trim();
    emailCtrl.dispose();
    nomeCtrl.dispose();
    if (ok != true || email.isEmpty) return;

    AnalyticsService.instance.track(
      ProductEvents.lojaCheckoutStarted,
      props: {'feature': 'loja', 'pacote_id': pacote.id},
    );

    try {
      final result = await ref.read(lojaRepositoryProvider).checkout(
        pacoteId: pacote.id,
        buyerEmail: email,
        buyerNome: nome.isEmpty ? null : nome,
      );

      if (!mounted) return;

      final pix = result.pixCopiaECola;
      await showFxNoticeSheet(
        context,
        title: 'PIX gerado',
        icon: Icons.qr_code_rounded,
        actionLabel: 'OK',
        message: pix.isEmpty ? 'Pedido criado.' : pix,
        extraActions: [
          if (pix.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () async {
                    await copySensitiveToClipboard(pix);
                    if (!mounted) return;
                    FeedbackHelper.showSuccess(context, 'Código copiado');
                  },
                  child: const Text('Copiar'),
                ),
              ),
            ),
        ],
      );

      await _load();
      if (!mounted) return;
      setState(() => _view = LojaHubView.pedidos);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
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
      icon: Icons.qr_code_rounded,
      message: lojaPedidoSubtitle(
        buyerNome: pedido.buyerNome,
        buyerEmail: pedido.buyerEmail,
        status: pedido.status,
      ),
      extraActions: [
        if (pix != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              height: 48,
              child: TextButton(
                onPressed: () async {
                  await copySensitiveToClipboard(pix);
                  if (!mounted) return;
                  FeedbackHelper.showSuccess(context, 'Código copiado');
                },
                child: const Text('Copiar PIX'),
              ),
            ),
          ),
        if (pendente)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              height: 48,
              child: Builder(
                builder: (sheetCtx) => TextButton(
                  onPressed: () async {
                    Navigator.of(sheetCtx).pop();
                    await _confirmarPedido(pedido);
                  },
                  child: const Text('Marcar pago'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmarPedido(LojaPedido pedido) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Marcar este PIX como pago?',
      subtitle: lojaPedidoLabel(
        buyerNome: pedido.buyerNome,
        buyerEmail: pedido.buyerEmail,
      ),
      message: formatBrlCurrency(pedido.valor),
      confirmLabel: 'Marcar pago',
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(lojaRepositoryProvider).confirmar(pedido.id);
      await _load();
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Pedido marcado como pago');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _carregarMaisPacotes() async {
    if (_carregandoMaisPacotes || !_pacotesHasNext) return;
    setState(() => _carregandoMaisPacotes = true);
    try {
      final pagina = await ref.read(lojaRepositoryProvider).listarPacotes(
        page: _pacotesPage + 1,
        q: _query,
      );
      if (!mounted) return;
      final seen = _pacotes.map((p) => p.id).toSet();
      setState(() {
        _pacotes = [
          ..._pacotes,
          ...pagina.content.where((p) => p.ativo && seen.add(p.id)),
        ];
        _pacotesPage = pagina.page ?? _pacotesPage + 1;
        _pacotesHasNext = pagina.hasNext;
        _pacotesTotal = pagina.totalElements ?? _pacotesTotal;
        _carregandoMaisPacotes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregandoMaisPacotes = false);
    }
  }

  Future<void> _carregarMaisPedidos() async {
    if (_carregandoMaisPedidos || !_pedidosHasNext) return;
    setState(() => _carregandoMaisPedidos = true);
    try {
      final pagina = await ref.read(lojaRepositoryProvider).pedidos(
        page: _pedidosPage + 1,
        q: _query,
      );
      if (!mounted) return;
      final seen = _pedidos.map((p) => p.id).toSet();
      setState(() {
        _pedidos = [
          ..._pedidos,
          ...pagina.content.where((p) => seen.add(p.id)),
        ];
        _pedidosPage = pagina.page ?? _pedidosPage + 1;
        _pedidosHasNext = pagina.hasNext;
        _pedidosTotal = pagina.totalElements ?? _pedidosTotal;
        _carregandoMaisPedidos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregandoMaisPedidos = false);
    }
  }

  Widget _buildVitrine() {
    final visible = _visiblePacotes;
    final primary = Theme.of(context).colorScheme.primary;
    if (visible.isEmpty) {
      final filtered = _query.trim().isNotEmpty;
      return RefreshIndicator(
        color: primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            FxEmptyState(
              icon: filtered ? 'search' : 'spark',
              title: filtered
                  ? 'Nenhum pacote encontrado'
                  : 'Nenhum pacote na vitrine',
              subtitle: filtered
                  ? 'Ajuste a busca.'
                  : 'Crie pacotes em Pacotes para vender pela loja.',
              action: filtered
                  ? FxEmptyAction(label: 'Limpar busca', onTap: _clearQuery)
                  : FxEmptyAction(
                      label: 'Ir para pacotes',
                      onTap: () => context.push('/pacotes'),
                    ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primary,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        itemCount: visible.length + (_pacotesHasNext ? 1 : 0),
        itemBuilder: (context, index) {
          if (_pacotesHasNext && index == visible.length) {
            return FxSatelliteListTile(
              title: _carregandoMaisPacotes ? 'Carregando…' : 'Carregar mais',
              onTap: _carregandoMaisPacotes ? null : _carregarMaisPacotes,
            );
          }
          final pacote = visible[index];
          return FxSatelliteListTile(
            title: pacote.titulo,
            subtitle: Text(
              lojaPacoteSubtitle(
                descricao: pacote.descricao,
                duracaoMeses: pacote.duracaoMeses,
              ),
            ),
            trailing: Text(
              formatBrlCurrency(pacote.valor, showDecimals: false),
              style: FocuxHubTypography.bodyMuted(
                color: fxScreenMute(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () => _checkoutPacote(pacote),
          );
        },
      ),
    );
  }

  Widget _buildPedidos() {
    final visible = _visiblePedidos;
    final primary = Theme.of(context).colorScheme.primary;
    if (visible.isEmpty) {
      final filtered = _query.trim().isNotEmpty;
      return RefreshIndicator(
        color: primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            FxEmptyState(
              icon: filtered ? 'search' : 'article',
              title: filtered
                  ? 'Nenhum pedido encontrado'
                  : 'Nenhum pedido ainda',
              subtitle: filtered
                  ? 'Ajuste a busca.'
                  : 'Gere um PIX na vitrine para ver pedidos aqui.',
              action: filtered
                  ? FxEmptyAction(label: 'Limpar busca', onTap: _clearQuery)
                  : null,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primary,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        itemCount: visible.length + (_pedidosHasNext ? 1 : 0),
        itemBuilder: (context, index) {
          if (_pedidosHasNext && index == visible.length) {
            return FxSatelliteListTile(
              title: _carregandoMaisPedidos ? 'Carregando…' : 'Carregar mais',
              onTap: _carregandoMaisPedidos ? null : _carregarMaisPedidos,
            );
          }
          final pedido = visible[index];
          return FxSatelliteListTile(
            title: lojaPedidoLabel(
              buyerNome: pedido.buyerNome,
              buyerEmail: pedido.buyerEmail,
            ),
            subtitle: Text(
              lojaPedidoSubtitle(
                buyerNome: pedido.buyerNome,
                buyerEmail: pedido.buyerEmail,
                status: pedido.status,
              ),
            ),
            trailing: Text(
              formatBrlCurrency(pedido.valor),
              style: FocuxHubTypography.bodyMuted(
                color: fxScreenMute(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () => _abrirPedido(pedido),
          );
        },
      ),
    );
  }
}
