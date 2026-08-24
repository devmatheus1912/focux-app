part of 'assinatura_screen.dart';

Color _paywallSecondaryText(Color ink, Color mute, {required bool isDark}) =>
    PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);

class _PaywallInlineNote extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color ink;
  final Color mute;
  final bool isDark;

  const _PaywallInlineNote({
    required this.icon,
    required this.text,
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return PaywallGlassCard(
      padding: const EdgeInsets.all(14),
      blur: false,
      elevationLevel: 4,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: mute),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: ink.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallLegalConsentLine extends StatefulWidget {
  final Color ink;
  final Color mute;
  final Color primary;
  final bool isUpgrade;

  const _PaywallLegalConsentLine({
    required this.ink,
    required this.mute,
    required this.primary,
    this.isUpgrade = false,
  });

  @override
  State<_PaywallLegalConsentLine> createState() =>
      _PaywallLegalConsentLineState();
}

class _PaywallLegalConsentLineState extends State<_PaywallLegalConsentLine> {
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = FocuxLegal.openTerms;
    _privacyTap = TapGestureRecognizer()..onTap = FocuxLegal.openPrivacy;
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = _paywallSecondaryText(
      widget.ink,
      widget.mute,
      isDark: isDark,
    );
    final body = TokensStrip.bodyMuted(
      color: secondary,
    ).copyWith(fontSize: 12, height: 1.45);
    final link = body.copyWith(
      fontWeight: FontWeight.w600,
      color: widget.primary,
      decoration: TextDecoration.underline,
      decorationColor: widget.primary.withValues(alpha: 0.45),
    );

    final lead =
        widget.isUpgrade
            ? 'Ao confirmar upgrade, você concorda com os '
            : 'Ao assinar, você concorda com os ';
    final semanticsLead =
        widget.isUpgrade
            ? 'Ao confirmar upgrade, você concorda com os Termos de uso e a Política de privacidade'
            : 'Ao assinar, você concorda com os Termos de uso e a Política de privacidade';

    return Semantics(
      label: semanticsLead,
      child: Text.rich(
        textAlign: TextAlign.center,
        TextSpan(
          style: body,
          children: [
            TextSpan(text: lead),
            TextSpan(text: 'Termos', style: link, recognizer: _termsTap),
            const TextSpan(text: ' e a '),
            TextSpan(text: 'Privacidade', style: link, recognizer: _privacyTap),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}
