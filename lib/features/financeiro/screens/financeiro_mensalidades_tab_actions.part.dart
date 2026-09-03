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
