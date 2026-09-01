import 'package:flutter/material.dart';

/// Permite que a aba Resumo peça a aba Mensalidades sem segundo scaffold.
class FinanceiroHubScope extends InheritedWidget {
  const FinanceiroHubScope({
    super.key,
    required this.goToMensalidades,
    required super.child,
  });

  final void Function({String source}) goToMensalidades;

  static FinanceiroHubScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FinanceiroHubScope>();
  }

  @override
  bool updateShouldNotify(FinanceiroHubScope oldWidget) => false;
}
