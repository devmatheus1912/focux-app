import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import 'auth_social_button.dart';
import 'google_logo_mark.dart';

/// Apple e Google empilhados, largura total, mesmo verbo e mesmo estilo.
/// A Apple vem primeiro (equivalência de destaque exigida pela App Store).
class AuthSocialStack extends StatelessWidget {
  const AuthSocialStack({
    super.key,
    required this.mostrarApple,
    required this.mostrarGoogle,
    required this.onApple,
    required this.onGoogle,
    required this.carregandoApple,
    required this.carregandoGoogle,
  });

  final bool mostrarApple;
  final bool mostrarGoogle;
  final VoidCallback? onApple;
  final VoidCallback? onGoogle;
  final bool carregandoApple;
  final bool carregandoGoogle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mostrarApple)
          AuthSocialButton(
            label: 'Continuar com Apple',
            leading: const Icon(Icons.apple, size: 24, color: Colors.white),
            loading: carregandoApple,
            onPressed: onApple,
          ),
        if (mostrarApple && mostrarGoogle) const SizedBox(height: TokensStrip.s3),
        if (mostrarGoogle)
          AuthSocialButton(
            label: 'Continuar com Google',
            leading: const GoogleLogoMark(),
            loading: carregandoGoogle,
            onPressed: onGoogle,
          ),
      ],
    );
  }
}
