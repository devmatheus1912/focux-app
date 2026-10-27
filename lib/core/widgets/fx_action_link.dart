import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';
import '../theme/focux_hub_typography.dart';
import 'fx_icon.dart';

/// Link de navegação ("Ver todos", "Abrir ficha"): texto + seta, área de 44 e
/// estado ao tocar. Nunca é só texto: a seta diz que é toque. Para ação que
/// grava ou conclui, use botão ([FxTonalButton] ou o preenchido).
class FxActionLink extends StatelessWidget {
  const FxActionLink({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onTap;

  /// Troca a seta final por outro ícone do conjunto [FxIcon] (ex.: 'plus').
  final String? icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cor = destructive ? EagleTokens.bad : primary;
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap:
            enabled
                ? () {
                  HapticFeedback.selectionClick();
                  onTap!();
                }
                : null,
        borderRadius: BorderRadius.circular(12),
        splashColor: cor.withValues(alpha: 0.10),
        highlightColor: cor.withValues(alpha: 0.06),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.bodyMuted(
                      color: enabled ? cor : cor.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                FxIcon(
                  name: icon ?? 'chevron-right',
                  size: 16,
                  color: enabled ? cor : cor.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
