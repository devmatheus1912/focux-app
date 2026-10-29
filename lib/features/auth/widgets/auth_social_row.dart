import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import 'apple_sign_in_button.dart';
import 'google_sign_in_button.dart';

/// Apple e Google lado a lado, com o mesmo peso (a Apple exige equivalência).
/// Com só um dos dois, ele ocupa a largura toda no tamanho normal.
class AuthSocialRow extends StatelessWidget {
  const AuthSocialRow({
    super.key,
    required this.mostrarApple,
    required this.mostrarGoogle,
    required this.onApple,
    required this.onGoogle,
    required this.carregandoApple,
    required this.carregandoGoogle,
    this.rotuloApple = 'Continuar com Apple',
    this.rotuloGoogle = 'Entrar com Google',
  });

  final bool mostrarApple;
  final bool mostrarGoogle;
  final VoidCallback? onApple;
  final VoidCallback? onGoogle;
  final bool carregandoApple;
  final bool carregandoGoogle;
  final String rotuloApple;
  final String rotuloGoogle;

  @override
  Widget build(BuildContext context) {
    final dois = mostrarApple && mostrarGoogle;
    final apple = AppleSignInButton(
      label: rotuloApple,
      isLoading: carregandoApple,
      onPressed: onApple,
      compacto: dois,
    );
    final google = GoogleSignInButton(
      label: rotuloGoogle,
      isLoading: carregandoGoogle,
      onPressed: onGoogle,
      dark: true,
      compacto: dois,
    );
    if (dois) {
      return Row(
        children: [
          Expanded(child: apple),
          const SizedBox(width: TokensStrip.s2),
          Expanded(child: google),
        ],
      );
    }
    return mostrarApple ? apple : google;
  }
}
