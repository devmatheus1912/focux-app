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
    this.enabled = true,
  });

  final String label;
  final Color accent;
  final bool isDark;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final fg = dashboardPrioritiesChipForeground(accent, isDark: isDark);
    final bg = dashboardPrioritiesChipBackground(accent, isDark: isDark);

    return Align(
      widthFactor: 1,
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: Opacity(
          opacity: enabled ? 1 : 0.42,
          child: Material(
            color: bg,
            elevation: enabled ? (isDark ? 4 : 2) : 0,
            shadowColor: accent.withValues(alpha: isDark ? 0.38 : 0.14),
            shape: const StadiumBorder(),
            child: InkWell(
              onTap:
                  enabled
                      ? () {
                        HapticFeedback.selectionClick();
                        onPressed();
                      }
                      : null,
              customBorder: const StadiumBorder(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 48,
                  minWidth: 48,
                ),
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
      ),
    );
  }
}
