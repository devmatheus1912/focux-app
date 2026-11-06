import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../utils/motion_preferences.dart';

Page<T> fxTransitionPage<T>({
  required GoRouterState state,
  required Widget child,
  bool fade = false,
}) {
  // No iPhone a página Cupertino traz o gesto de voltar pela borda; a
  // transição própria abaixo não tem gesto nenhum.
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPage<T>(
      key: state.pageKey,
      name: state.name ?? state.path,
      child: child,
    );
  }
  return CustomTransitionPage<T>(
    key: state.pageKey,
    name: state.name ?? state.path,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (reduceMotionOf(context)) {
        return child;
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      if (fade) {
        return FadeTransition(opacity: curved, child: child);
      }
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.035),
        end: Offset.zero,
      ).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
