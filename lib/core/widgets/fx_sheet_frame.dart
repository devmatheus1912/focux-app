import 'package:flutter/material.dart';

import '../theme/tokens_strip.dart';
import 'fx_home_sheet.dart';
import 'fx_keyboard_dismiss_scope.dart';

/// Moldura de folha: cabeçalho **fixo** (nunca cortado), corpo que rola por
/// baixo e rodapé fixo opcional (ação principal sempre visível).
class FxSheetFrame extends StatelessWidget {
  const FxSheetFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.footer,
    this.maxHeightFactor = FxHomeSheetChrome.maxHeightFactor,
    this.expand = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget child;

  /// Fica abaixo do corpo, fora da rolagem.
  final Widget? footer;
  final double maxHeightFactor;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFactor;
    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight: maxHeight,
      expand: expand,
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          const SizedBox(height: TokensStrip.s3),
          FxHomeSheetHeader(
            isDark: isDark,
            leading: leading,
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: TokensStrip.s3),
          Flexible(
            fit: expand ? FlexFit.tight : FlexFit.loose,
            child: FxKeyboardDismissScope(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: child,
              ),
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: TokensStrip.s3),
            footer!,
          ],
        ],
      ),
    );
  }
}
