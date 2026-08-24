part of 'paywall_components.dart';

/// Rodapé legal enxuto para assinante no plano atual (sem bloco de compra).
class PaywallSubscriberLegalStrip extends StatelessWidget {
  final Color mute;
  final Color primary;
  final VoidCallback? onRestore;
  final bool restoring;

  const PaywallSubscriberLegalStrip({
    super.key,
    required this.mute,
    required this.primary,
    this.onRestore,
    this.restoring = false,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle link() => TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: primary,
      decoration: TextDecoration.underline,
    );
    final linkStyle = TextButton.styleFrom(
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 0,
      children: [
        Semantics(
          button: true,
          label: 'Abrir política de privacidade',
          child: TextButton(
            onPressed: () => FocuxLegal.openPrivacy(),
            style: linkStyle,
            child: Text('Privacidade', style: link()),
          ),
        ),
        Semantics(
          button: true,
          label: 'Abrir termos de uso',
          child: TextButton(
            onPressed: () => FocuxLegal.openTerms(),
            style: linkStyle,
            child: Text('Termos', style: link()),
          ),
        ),
        if (onRestore != null)
          Semantics(
            button: true,
            label:
                restoring
                    ? 'Restaurando compras'
                    : 'Restaurar compras anteriores',
            child: TextButton(
              onPressed: restoring ? null : onRestore,
              style: linkStyle,
              child: Text(
                restoring ? 'Restaurando…' : 'Restaurar compras',
                style: link(),
              ),
            ),
          ),
      ],
    );
  }
}
