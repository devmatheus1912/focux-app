import 'package:flutter/widgets.dart';

import 'brand_style.dart';

/// Marca do personal disponível para qualquer widget, sem depender de
/// Riverpod (testes de widget não precisam de `ProviderScope`). Ausente =
/// interface padrão. Posto uma vez no `MaterialApp.builder`.
class BrandTint extends InheritedWidget {
  const BrandTint({
    super.key,
    required this.estilo,
    required this.primaria,
    required this.secundaria,
    required super.child,
  });

  final BrandStyle estilo;
  final Color primaria;
  final Color secundaria;

  static BrandTint? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BrandTint>();

  /// Estilo atual; Clássico quando não há marca no contexto.
  static BrandStyle estiloDe(BuildContext context) =>
      maybeOf(context)?.estilo ?? BrandStyle.classico;

  @override
  bool updateShouldNotify(BrandTint old) =>
      estilo != old.estilo ||
      primaria != old.primaria ||
      secundaria != old.secundaria;
}
