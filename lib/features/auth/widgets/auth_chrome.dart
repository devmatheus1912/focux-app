import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({
    super.key,
    required this.onTap,
    this.showLabel = false,
  });

  final VoidCallback onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final icon = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          FxKeyboardDismissScope.dismiss();
          onTap();
        },
        customBorder: const CircleBorder(),
        child: Ink(
          width: 38,
          height: 38,
          decoration: TokensStrip.glassPanel(
            dark: true,
            radius: 19,
            accent: primary,
            elevationLevel: 4,
          ),
          child: Center(
            child: Icon(
              Icons.chevron_left_rounded,
              color: Colors.white.withValues(alpha: 0.92),
              size: 22,
            ),
          ),
        ),
      ),
    );

    final button = Semantics(button: true, label: 'Voltar', child: icon);

    if (!showLabel) {
      return button;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(width: 10),
        Text(
          'Voltar',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Barra do topo das telas de formulário: só o botão de voltar. O papel já
/// está no logo ("Focux Personal" / "Focux Aluno").
class AuthBackBar extends StatelessWidget {
  const AuthBackBar({super.key, required this.onBack, this.semanticLabel});

  final VoidCallback onBack;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AuthBackButton(onTap: onBack),
      ),
    );
  }
}
