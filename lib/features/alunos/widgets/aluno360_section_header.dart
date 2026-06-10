import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
import '../utils/aluno360_a11y.dart';

/// Shared section header for Operação and Evolução inset cards.
class Aluno360SectionHeader extends StatelessWidget {
  const Aluno360SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.subtitleTrailing,
    this.trailingSemanticsLabel,
    this.compact = false,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? subtitleTrailing;
  final String? trailingSemanticsLabel;
  final bool compact;
  final bool isDark;

  static const double _iconSize = 36;
  static const double _iconRadius = 12;
  static const double _iconGlyphSize = 18;
  static const double _compactIconSize = 32;
  static const double _compactIconRadius = 10;
  static const double _compactIconGlyphSize = 16;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final iconBox = compact ? _compactIconSize : _iconSize;
    final iconRadius = compact ? _compactIconRadius : _iconRadius;
    final iconGlyph = compact ? _compactIconGlyphSize : _iconGlyphSize;
    final titleStyle =
        compact
            ? Aluno360Layout.compactSectionTitleStyle(context, ink)
            : Aluno360Layout.sectionTitleStyle(context, ink);

    return Semantics(
      header: true,
      label: aluno360SectionHeaderSemantics(
        title: title,
        subtitle: subtitle,
        trailing: trailingSemanticsLabel,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: BrandPalette.soft(primary, dark: isDark),
              borderRadius: BorderRadius.circular(iconRadius),
            ),
            child: Icon(icon, color: primary, size: iconGlyph),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  LayoutBuilder(
                    builder: (context, subtitleConstraints) {
                      final stackTrailing =
                          subtitleTrailing != null &&
                          subtitleConstraints.maxWidth < 220;
                      if (stackTrailing) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subtitle!,
                              maxLines: compact ? 2 : 3,
                              overflow: TextOverflow.ellipsis,
                              style: Aluno360Layout.captionStyle(
                                context,
                              ).copyWith(color: mute, height: 1.3),
                            ),
                            const SizedBox(height: 4),
                            subtitleTrailing!,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              subtitle!,
                              maxLines: compact ? 2 : 3,
                              overflow: TextOverflow.ellipsis,
                              style: Aluno360Layout.captionStyle(
                                context,
                              ).copyWith(color: mute, height: 1.3),
                            ),
                          ),
                          if (subtitleTrailing != null) ...[
                            const SizedBox(width: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topRight,
                              child: subtitleTrailing!,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Align(alignment: Alignment.topRight, child: trailing!),
            ),
          ],
        ],
      ),
    );
  }
}
