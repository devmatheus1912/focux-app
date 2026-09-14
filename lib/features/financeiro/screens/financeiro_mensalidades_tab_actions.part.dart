part of 'financeiro_mensalidades_tab.dart';

extension FinanceiroMensalidadesTabActions on _FinanceiroMensalidadesTabState {
  Future<void> _abrirAcoes(Mensalidade m) async {
    final result = await context.push<String>(
      '/financeiro/mensalidades/${m.id}',
      extra: m,
    );
    if (!mounted || result != 'changed') return;
    _load(force: true);
  }

  void _entrarModoLote() {
    setState(() {
      _modoSelecao = true;
      _selecionados.clear();
    });
  }

  void _sairModoLote() {
    setState(() {
      _modoSelecao = false;
      _selecionados.clear();
    });
  }

  void _toggleLote(Mensalidade m) {
    if (!financeiroStatusAberto(m.status)) return;
    setState(() {
      if (!_selecionados.add(m.id)) {
        _selecionados.remove(m.id);
      }
    });
  }

  Future<void> _confirmarLotePago() async {
    if (_selecionados.isEmpty) return;
    final qtd = _selecionados.length;
    final ok = await showFxConfirmSheet(
      context,
      title: 'Marcar lote como pago?',
      message: financeiroLotePagoConfirmMessage(qtd),
      confirmLabel: financeiroLotePagoChipLabel(
        modoSelecao: true,
        selecionados: qtd,
      ),
    );
    if (!ok || !mounted) return;
    try {
      await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).marcarLotePago(_selecionados.toList());
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, financeiroLotePagoSuccess(qtd));
      _sairModoLote();
      await _load(force: true);
    } catch (e) {
      if (!mounted) return;
      final surfaced = await UpgradePromptSheet.showFromError(
        context,
        e,
        fallbackFeatureName: 'Financeiro',
        fallbackCapability: 'financeiro',
        source: 'financeiro_lote_pago',
      );
      if (surfaced) return;
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
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
}
