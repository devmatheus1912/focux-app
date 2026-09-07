import 'package:flutter/material.dart';

import '../theme/tokens_strip.dart';
import 'fx_form_chrome.dart';

/// Footer S9: primário full-width, Voltar em texto, sobe com o teclado.
class FxWizardStickyBar extends StatelessWidget {
  const FxWizardStickyBar({
    super.key,
    required this.primary,
    this.secondary,
  });

  final Widget primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    return FxFormStickyBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (secondary != null) ...[
            secondary!,
            const SizedBox(height: TokensStrip.s2),
          ],
          primary,
        ],
      ),
    );
  }
}

/// Back do SO: fecha teclado, depois entrega o sair do wizard.
class FxWizardPopGuard extends StatelessWidget {
  const FxWizardPopGuard({
    super.key,
    required this.onLeave,
    required this.child,
  });

  final Future<void> Function() onLeave;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FxFormPopGuard(dirty: true, onCancel: onLeave, child: child);
  }
}
