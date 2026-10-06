part of 'financeiro_mensalidades_tab.dart';

extension FinanceiroMensalidadesTabWidgets on _FinanceiroMensalidadesTabState {
  Widget _buildMensalidadesLoading(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 4),
      child: SkeletonList(count: 5),
    );
  }

  Widget _buildMensalidadesEmpty(BuildContext context) {
    // Create fica só no sticky — evita dois CTAs iguais no vazio (§11).
    final s = S.of(context);
    if (_buscaAtiva.isNotEmpty ||
        _filtro == MensalidadeFiltro.atrasadas ||
        _filtro == MensalidadeFiltro.pagas) {
      return FxEmptyState(
        icon: 'search',
        title: s.financeiroVazioFiltroTitulo,
        subtitle: s.financeiroVazioFiltroTexto,
      );
    }
    if (_filtro == MensalidadeFiltro.abertas) {
      return FxEmptyState(
        icon: 'circle-check',
        title: s.financeiroVazioAbertasTitulo,
        subtitle: s.financeiroVazioAbertasTexto,
      );
    }
    return const FxEmptyState(
      icon: 'coin',
      title: 'Nenhuma mensalidade',
      subtitle: 'Lance a primeira cobrança para começar o mês.',
    );
  }
}
