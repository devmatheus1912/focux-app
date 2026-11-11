import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/brand_style.dart';
import 'package:focux_app/features/perfil/widgets/identidade_estilo_miniaturas.dart';

Future<void> _montar(WidgetTester tester, double escala) {
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(escala)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: IdentidadeEstiloMiniaturas(
              selecionado: BrandStyle.classico,
              primaria: const Color(0xFF0D9488),
              onSelecionar: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('letra normal: três lado a lado', (tester) async {
    await _montar(tester, 1.0);
    final a = tester.getTopLeft(find.text('Clássico'));
    final b = tester.getTopLeft(find.text('Minimalista'));
    expect(a.dy, closeTo(b.dy, 2));
  });

  testWidgets('letra grande: um estilo por linha, nome inteiro', (tester) async {
    await _montar(tester, 1.5);
    final a = tester.getTopLeft(find.text('Clássico'));
    final b = tester.getTopLeft(find.text('Minimalista'));
    expect(b.dy, greaterThan(a.dy));
    final texto = tester.widget<Text>(find.text('Minimalista'));
    expect(texto.overflow, isNot(TextOverflow.ellipsis));
  });
}
