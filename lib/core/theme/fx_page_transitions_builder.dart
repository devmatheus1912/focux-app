import 'package:flutter/material.dart';

/// Premium fade + slide transition applied globally via [ThemeData.pageTransitionsTheme].
class FxPremiumPageTransitionsBuilder extends PageTransitionsBuilder {
  const FxPremiumPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.028),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

const fxPremiumPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: FxPremiumPageTransitionsBuilder(),
    TargetPlatform.iOS: FxPremiumPageTransitionsBuilder(),
    TargetPlatform.linux: FxPremiumPageTransitionsBuilder(),
    TargetPlatform.macOS: FxPremiumPageTransitionsBuilder(),
    TargetPlatform.windows: FxPremiumPageTransitionsBuilder(),
    TargetPlatform.fuchsia: FxPremiumPageTransitionsBuilder(),
  },
);
