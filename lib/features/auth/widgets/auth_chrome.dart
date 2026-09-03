import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
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

/// Barra fixa de marca no cadastro / esqueci — back + papel sempre no viewport.
class AuthStickyRoleBar extends StatelessWidget {
  const AuthStickyRoleBar({
    super.key,
    required this.roleLabel,
    required this.onBack,
  });

  final String roleLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Focux $roleLabel',
      child: Padding(
        padding: const EdgeInsets.only(bottom: TokensStrip.s2),
        child: Row(
          children: [
            AuthBackButton(onTap: onBack),
            Expanded(
              child: Text(
                '— ${roleLabel.toUpperCase()} —',
                textAlign: TextAlign.center,
                style: FocuxHubTypography.chip(
                  primary.withValues(alpha: 0.92),
                ).copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.4,
                ),
              ),
            ),
            const SizedBox(width: 38),
          ],
        ),
      ),
    );
  }
}
