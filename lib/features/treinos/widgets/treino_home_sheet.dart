import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_home_sheet.dart';

class TreinoHomeSheetSurface extends StatelessWidget {
  const TreinoHomeSheetSurface({
    super.key,
    required this.isDark,
    required this.child,
    this.maxHeight,
    this.expand = false,
    this.padding = FxHomeSheetChrome.contentPadding,
  });

  final bool isDark;
  final Widget child;
  final double? maxHeight;
  final bool expand;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight: maxHeight,
      expand: expand,
      padding: padding,
      child: child,
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
    final soft = BrandPalette.softened(
      Theme.of(context).colorScheme.primary,
    );
    return FxHomeSheetHeader(
      isDark: isDark,
      title: title,
      subtitle: subtitle,
      leading: Icon(icon, color: soft, size: FxSettingsLayout.iconSize),
    );
  }
}
