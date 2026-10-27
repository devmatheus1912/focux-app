import 'package:flutter/material.dart';

import 'data/financeiro_repository.dart';

/// Permite que Resumo e Métricas abram a lista de mensalidades no mesmo hub.
class FinanceiroHubScope extends InheritedWidget {
  const FinanceiroHubScope({
    super.key,
    required this.goToMensalidades,
    required this.openNovaMensalidade,
    required this.openFiltro,
    required super.child,
  });

  final void Function({String source}) goToMensalidades;
  /// Troca para Mensalidades e abre o formulário de lançamento (job §37).
  final void Function({String source}) openNovaMensalidade;

  /// Troca para Mensalidades já com esse filtro (ex.: Resultados para Atrasadas).
  final void Function(MensalidadeFiltro filtro) openFiltro;

  static FinanceiroHubScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FinanceiroHubScope>();
  }

  @override
  bool updateShouldNotify(FinanceiroHubScope oldWidget) => false;
}
