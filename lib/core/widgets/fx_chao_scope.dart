import 'package:flutter/material.dart';

/// Avisa que um [FxChao] já pinta o fundo num ancestral (shell ou rota).
class FxChaoScope extends InheritedWidget {
  const FxChaoScope({super.key, required this.active, required super.child});

  final bool active;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FxChaoScope>()?.active ??
      false;

  @override
  bool updateShouldNotify(FxChaoScope oldWidget) => active != oldWidget.active;
}
