part of 'financeiro_mensalidades_tab.dart';

extension FinanceiroMensalidadesTabActions on _FinanceiroMensalidadesTabState {
  Future<void> _abrirAcoes(Mensalidade m) async {
    final result = await context.push<String>(
      '/financeiro/mensalidades/${m.id}',
      extra: m,
    );
    if (!mounted || result == null) return;
    switch (result) {
      case 'edit':
        await _editarMensalidade(m);
      case 'chat':
        await _cobrarViaChat(m);
      case 'contato':
        await _registrarContato(m);
      case 'pix':
        await _mostrarPix(m.id);
      case 'pay':
        await _pagar(m);
      case 'changed':
        _load(force: true);
    }
  }

  Future<void> _atualizarAtrasos() async {
    try {
      await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).atualizarAtrasos();
      _load(force: true);
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Mensalidades atualizadas!');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _cobrarViaChat(Mensalidade m) async {
    AnalyticsService.instance.track(
      ProductEvents.financeiroCobrarViaChat,
      props: {
        'feature': 'financeiro',
        'mensalidade_id': m.id,
        'aluno_id': m.alunoId,
      },
    );
    try {
      final msg = await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).cobrarViaChat(m.id);
      if (mounted) {
        FeedbackHelper.showSuccess(context, msg);
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _pagar(Mensalidade m) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Marcar como paga?',
      subtitle: m.alunoNome,
      message:
          'Confirme só se o valor já entrou. O status passa a pago.',
      confirmLabel: 'Marcar paga',
    );
    if (!ok || !mounted) return;
    try {
      await FinanceiroRepository(ref.read(apiClientProvider)).pagar(m.id);
      _load(force: true);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _mostrarPix(int id) async {
    PixData? pix;
    bool carregando = true;
    String? erro;

    await showFxHomeSheet<void>(
      context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setDialogState) {
              if (carregando && pix == null && erro == null) {
                FinanceiroRepository(ref.read(apiClientProvider))
                    .gerarPix(id)
                    .then((p) {
                      setDialogState(() {
                        pix = p;
                        carregando = false;
                      });
                    })
                    .catchError((e) {
                      setDialogState(() {
                        erro = friendlyError(e);
                        carregando = false;
                      });
                    });
              }

              final isDark = Theme.of(ctx).brightness == Brightness.dark;
              final primary = Theme.of(ctx).colorScheme.primary;
              return FxHomeSheetSurface(
                isDark: isDark,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FxHomeSheetHandle(isDark: isDark),
                    SizedBox(height: TokensStrip.s4),
                    FxHomeSheetHeader(
                      isDark: isDark,
                      title: 'PIX - Escaneie ou copie',
                      leading: FxIcon(
                        name: 'pix',
                        color: primary,
                        size: 18,
                      ),
                    ),
                    SizedBox(height: TokensStrip.s4),
                    if (carregando)
                      const SizedBox(height: 80, child: FxLoading())
                    else if (erro != null)
                      Text(
                        erro!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: EagleTokens.bad,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else ...[
                      Image.memory(
                        base64Decode(pix!.qrCodeBase64),
                        width: 200,
                        height: 200,
                      ),
                      const SizedBox(height: TokensStrip.s4),
                      TextButton.icon(
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar codigo PIX'),
                        onPressed: () async {
                          await copySensitiveToClipboard(pix!.pixCopiaECola);
                          if (ctx.mounted) {
                            FeedbackHelper.showSuccess(
                              ctx,
                              'Código PIX copiado. Some em 1 min.',
                            );
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Fechar'),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}

