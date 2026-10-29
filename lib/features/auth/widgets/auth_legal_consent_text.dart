import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/legal/focux_legal.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/hero_teal.dart';

/// Aceite dos Termos e da Política. Curto por padrão (login com Apple/Google);
/// [completo] acrescenta a regra de conteúdo, só nas telas de criar conta.
class AuthLegalConsentText extends StatefulWidget {
  const AuthLegalConsentText({
    super.key,
    required this.primary,
    this.completo = false,
  });

  final Color primary;
  final bool completo;

  @override
  State<AuthLegalConsentText> createState() => _AuthLegalConsentTextState();
}

class _AuthLegalConsentTextState extends State<AuthLegalConsentText> {
  late final TapGestureRecognizer _termos =
      TapGestureRecognizer()..onTap = FocuxLegal.openTerms;
  late final TapGestureRecognizer _privacidade =
      TapGestureRecognizer()..onTap = FocuxLegal.openPrivacy;

  @override
  void dispose() {
    _termos.dispose();
    _privacidade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final link = TextStyle(color: widget.primary, fontWeight: FontWeight.w700);
    return Center(
      child: Text.rich(
        TextSpan(
          style: FocuxHubTypography.bodyMuted(
            color: heroTealSurface(0.78),
            height: 1.45,
          ),
          children: [
            TextSpan(
              text: widget.completo
                  ? 'Ao criar, você concorda com os '
                  : 'Ao continuar, você aceita os ',
            ),
            TextSpan(text: 'Termos de uso', style: link, recognizer: _termos),
            const TextSpan(text: ' e a '),
            TextSpan(
              text: 'Política de privacidade',
              style: link,
              recognizer: _privacidade,
            ),
            TextSpan(
              text:
                  widget.completo
                      ? '. Conteúdo ofensivo ou abusivo não é tolerado: '
                          'denúncias são analisadas em até 24 horas e a conta '
                          'pode ser removida.'
                      : '.',
            ),
          ],
        ),
        textAlign: TextAlign.center,
        softWrap: true,
      ),
    );
  }
}
