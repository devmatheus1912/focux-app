part of 'financeiro_mensalidades_tab.dart';

enum _MensalidadeAcao { editar, chat, contato, pix, pagar }

extension FinanceiroMensalidadesTabActions on _FinanceiroMensalidadesTabState {
  Future<void> _abrirAcoes(Mensalidade m) async {
    final pending = m.status == 'PENDENTE' || m.status == 'ATRASADO';
    final picked = await showFxInsetPickerSheet<_MensalidadeAcao>(
      context,
      title: m.alunoNome,
      subtitle: financeiroMensalidadeSubtitle(m.status, m.mesReferencia),
      items: [
        const FxInsetPickerSheetItem(
          value: _MensalidadeAcao.editar,
          label: 'Editar',
        ),
        if (pending) ...[
          const FxInsetPickerSheetItem(
            value: _MensalidadeAcao.chat,
            label: 'Cobrar no chat',
          ),
          const FxInsetPickerSheetItem(
            value: _MensalidadeAcao.contato,
            label: 'Registrar contato',
          ),
          const FxInsetPickerSheetItem(
            value: _MensalidadeAcao.pix,
            label: 'PIX',
          ),
          const FxInsetPickerSheetItem(
            value: _MensalidadeAcao.pagar,
            label: 'Marcar paga',
          ),
        ],
      ],
    );
    if (!mounted || picked == null) return;
    switch (picked) {
      case _MensalidadeAcao.editar:
        await _editarMensalidade(m);
      case _MensalidadeAcao.chat:
        await _cobrarViaChat(m);
      case _MensalidadeAcao.contato:
        await _registrarContato(m);
      case _MensalidadeAcao.pix:
        await _mostrarPix(m.id);
      case _MensalidadeAcao.pagar:
        await _pagar(m);
    }
  }

  InputDecoration _fxDeco(String label, {IconData? icon, String? hint}) {
    final chrome = ShellChrome.of(context);
    final line = chrome.line;
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        color: mute,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(color: mute.withValues(alpha: 0.5), fontSize: 13.5),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: mute) : null,
      filled: true,
      fillColor: chrome.cardFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: FxInputDeco.outlineBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: FxInputDeco.outlineBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: FxInputDeco.outlineBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 1.6),
      ),
      errorBorder: FxInputDeco.outlineBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EagleTokens.bad),
      ),
      focusedErrorBorder: FxInputDeco.outlineBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EagleTokens.bad, width: 1.6),
      ),
    );
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

