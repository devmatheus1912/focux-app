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
    return const FxEmptyState(
      icon: 'coin',
      title: 'Nenhuma mensalidade',
      subtitle: 'Lance a primeira cobrança para começar o mês.',
    );
  }
}
