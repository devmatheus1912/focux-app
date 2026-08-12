import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';

/// Tile de ação padrão do hub Perfil.
class PerfilActionTile extends StatelessWidget {
  const PerfilActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.actionInk,
    required this.mute,
    required this.line,
    required this.onTap,
    this.danger = false,
    this.showDivider = true,
    this.locked = false,
    this.upgradeTierLabel,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color? actionInk;
  final Color mute;
  final Color line;
  final bool danger;
  final bool showDivider;
  final bool locked;
  final String? upgradeTierLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink =
        danger
            ? EagleTokens.bad
            : (isDark ? EagleTokens.darkInk : TokensStrip.textPrimary);
    final inkMuted = locked ? ink.withValues(alpha: 0.55) : ink;

    final link = actionInk ?? accent;
    final a11y =
        danger
            ? label
            : locked
            ? '$label trancado. Plano ${upgradeTierLabel ?? 'upgrade'}'
            : (value.isEmpty ? label : '$label. $value');

    return Semantics(
      button: true,
      label: a11y,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            border:
                showDivider
                    ? Border(bottom: BorderSide(color: line, width: 0.5))
                    : null,
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _LeadingIcon(
                    icon: icon,
                    background:
                        danger
                            ? EagleTokens.badSoft
                            : (isDark
                                ? accent.withValues(alpha: locked ? 0.08 : 0.14)
                                : BrandPalette.soft(
                                  accent,
                                ).withValues(alpha: locked ? 0.55 : 1)),
                    color:
                        danger
                            ? ink
                            : accent.withValues(alpha: locked ? 0.55 : 1),
                  ),
                  if (locked)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? EagleTokens.darkCard
                                  : TokensStrip.cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: line),
                        ),
                        child: Icon(Icons.lock_rounded, size: 10, color: mute),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TokensStrip.body(color: inkMuted).copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: TokensStrip.fontBodySm + 1,
                  ),
                ),
              ),
              if (value.isNotEmpty)
                Flexible(
                  flex: 5,
                  child: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TokensStrip.bodyMuted(
                      color: danger ? ink : (locked ? mute : link),
                    ).copyWith(
                      fontWeight: danger ? FontWeight.w600 : FontWeight.w800,
                    ),
                  ),
                ),
              if (!danger) ...[
                const SizedBox(width: 8),
                Icon(
                  locked ? Icons.lock_outline_rounded : Icons.chevron_right,
                  size: 18,
                  color: locked ? mute : link,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({
    required this.icon,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
