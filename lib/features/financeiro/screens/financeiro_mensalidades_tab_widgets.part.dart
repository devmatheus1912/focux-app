part of 'financeiro_mensalidades_tab.dart';

extension FinanceiroMensalidadesTabWidgets on _FinanceiroMensalidadesTabState {
  Widget _buildMensalidadesLoading(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 4, 16, 80),
      itemCount: 5,
      itemBuilder:
          (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 82,
              decoration: fxListCardDecoration(context, radius: 20),
              child: const SizedBox.shrink(),
            ),
          ),
    );
  }

  Widget _buildMensalidadesEmpty(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: chrome.isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.receipt_long_rounded, color: primary, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhuma mensalidade',
            style: AppTypography.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque + para lançar a primeira.',
            style: TextStyle(color: mute, fontSize: 13),
          ),
        ],
      ),
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
