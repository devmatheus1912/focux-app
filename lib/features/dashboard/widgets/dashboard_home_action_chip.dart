import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/tokens_strip.dart';
import '../utils/dashboard_readability.dart';

/// Chip de ação no fold da Home — mesmo peso do sticky Perfil (`Completar`/`Hoje`).
/// Não é CTA invertido (branco no preto) nem botão full-width do Planos.
class DashboardHomeActionChip extends StatelessWidget {
  const DashboardHomeActionChip({
    super.key,
    required this.label,
    required this.accent,
    required this.isDark,
    required this.onPressed,
  });

  final String label;
  final Color accent;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fg = dashboardPrioritiesChipForeground(accent, isDark: isDark);
    final bg = dashboardPrioritiesChipBackground(accent, isDark: isDark);

    return Semantics(
      button: true,
      label: label,
      child: UnconstrainedBox(
        child: Material(
          color: bg,
          elevation: isDark ? 4 : 2,
          shadowColor: accent.withValues(alpha: isDark ? 0.38 : 0.14),
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onPressed();
            },
            customBorder: const StadiumBorder(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TokensStrip.s4,
                ),
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: dashboardChipLabelStyle(fg).copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
