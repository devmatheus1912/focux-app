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
}
