part of 'financeiro_mensalidades_tab.dart';

extension FinanceiroMensalidadesTabWidgets on _FinanceiroMensalidadesTabState {
  Widget _buildMensalidadesLoading(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 4),
      child: SkeletonList(count: 5),
    );
  }

  Widget _buildMensalidadesEmpty(BuildContext context) {
    return const FxEmptyState(
      icon: 'dollar-sign',
      title: 'Nenhuma mensalidade',
      subtitle: 'Toque + para lançar a primeira.',
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MiniAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: chrome.headerAction(radius: 10),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
