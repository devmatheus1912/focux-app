import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';

/// Shared section header for Operação and Evolução inset cards (40×40 icon + title).
class Aluno360SectionHeader extends StatelessWidget {
  const Aluno360SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool isDark;

  static const double iconSize = 40;
  static const double iconRadius = 15;
  static const double iconGlyphSize = 20;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: BrandPalette.soft(primary, dark: isDark),
            borderRadius: BorderRadius.circular(iconRadius),
          ),
          child: Icon(icon, color: primary, size: iconGlyphSize),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Aluno360Layout.sectionTitleStyle(context, ink),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: Aluno360Layout.captionStyle(context).copyWith(
                    color: mute,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
