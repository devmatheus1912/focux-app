import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/treinos_layout.dart';

BoxDecoration treinoHomeSheetDecoration(
  BuildContext context, {
  required bool isDark,
}) {
  return fxStripCardDecoration(
    context,
    radius: 28,
    glowStrength: isDark ? 0.10 : 0.16,
  );
}

class TreinoHomeSheetSurface extends StatelessWidget {
  const TreinoHomeSheetSurface({
    super.key,
    required this.isDark,
    required this.child,
    this.maxHeight,
    this.padding = const EdgeInsets.fromLTRB(18, 10, 18, 18),
  });

  final bool isDark;
  final Widget child;
  final double? maxHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: TreinosLayout.homeSheetPadding(context),
      child: Container(
        constraints:
            maxHeight == null ? null : BoxConstraints(maxHeight: maxHeight!),
        clipBehavior: Clip.antiAlias,
        padding: padding,
        decoration: treinoHomeSheetDecoration(context, isDark: isDark),
        child: child,
      ),
    );
  }
}

class TreinoSheetChromeHeader extends StatelessWidget {
  const TreinoSheetChromeHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: BrandPalette.soft(primary, dark: isDark),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: primary, size: 18),
        ),
        SizedBox(width: TokensStrip.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TokensStrip.h2(
                  color: primary,
                  fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                ),
              ),
              SizedBox(height: TokensStrip.s1),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.bodyMuted(
                  color: chrome.mute,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Fechar',
          onPressed: () => Navigator.of(context).pop(),
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.close_rounded, size: 18, color: chrome.mute),
        ),
      ],
    );
  }
}
