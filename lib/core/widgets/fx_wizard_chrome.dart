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

/// Progresso discreto S9 — bolinhas da etapa atual.
class FxWizardStepDots extends StatelessWidget {
  const FxWizardStepDots({
    super.key,
    required this.current,
    required this.total,
    this.color,
  });

  /// 1-based etapa atual.
  final int current;
  final int total;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final n = total <= 0 ? 1 : total;
    final active = current.clamp(1, n);
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Etapa $active de $n',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= n; i++) ...[
            if (i > 1) const SizedBox(width: TokensStrip.s2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: i == active ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    i <= active
                        ? accent
                        : accent.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
