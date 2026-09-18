part of 'financeiro_mensalidades_tab.dart';

extension FinanceiroMensalidadesTabWidgets on _FinanceiroMensalidadesTabState {
  Widget _buildMensalidadesLoading(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 4),
      child: SkeletonList(count: 5),
    );
  }

  Widget _buildMensalidadesEmpty(BuildContext context) {
    return FxEmptyState(
      icon: 'dollar-sign',
      title: 'Nenhuma mensalidade',
      subtitle: 'Lance a primeira cobrança pelo botão abaixo.',
    );
  }
}
