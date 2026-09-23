import 'package:flutter/material.dart';

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
