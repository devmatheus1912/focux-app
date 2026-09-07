import 'package:flutter/material.dart';

/// Quando presente, [FxShellScaffold] omite app bar/mesh duplicados (aba de hub).
class HubEmbedScope extends InheritedWidget {
  const HubEmbedScope({super.key, required super.child});

  static bool of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HubEmbedScope>() != null;
  }

  static bool maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<HubEmbedScope>() != null;
  }

  @override
  bool updateShouldNotify(covariant HubEmbedScope oldWidget) => false;
}
