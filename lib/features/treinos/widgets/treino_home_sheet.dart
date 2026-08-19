import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../dashboard/utils/dashboard_readability.dart';
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
    final primary = Theme.of(context).colorScheme.primary;
    final caption = dashboardReadableCaption(context, isDark: isDark);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: BrandPalette.soft(primary, dark: isDark),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: primary, size: 18),
          ),
        ),
        SizedBox(width: TokensStrip.s3),
        Expanded(
          child: Semantics(
            header: true,
            label: '$title. $subtitle',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TokensStrip.h2(
                    color: primary,
                    fontFamily:
                        Theme.of(context).textTheme.bodyLarge?.fontFamily,
                  ),
                ),
                SizedBox(height: TokensStrip.s1),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.bodyMuted(
                    color: caption,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Fechar',
          onPressed: () => Navigator.of(context).pop(),
          style: IconButton.styleFrom(
            minimumSize: const Size(
              TreinosLayout.touchTarget,
              TreinosLayout.touchTarget,
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: caption,
          ),
          icon: const Icon(Icons.close_rounded, size: 22),
        ),
      ],
    );
  }
}
