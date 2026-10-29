import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/checkin_screen_harness.dart';

/// A folha Ajustar não repete carga e reps e deixa o esforço como detalhe.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> abrirAjustar(WidgetTester tester, Size tela) async {
    await pumpCheckin(tester, FakeCheckinRepo(), tela: tela);
    await tester.tap(find.byTooltip('Mais'));
    await pumpSheet(tester);
    await tester.tap(find.text('Ajustar'));
    await pumpSheet(tester);
  }

  testWidgets('não pede carga nem reps de novo e começa com "Como foi?"', (
    tester,
  ) async {
    await abrirAjustar(tester, const Size(390, 844));
    expect(find.text('Como foi?'), findsOneWidget);
    expect(find.text('Fácil'), findsOneWidget);
    expect(find.text('Dor'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Carga'), findsNothing);
    expect(find.widgetWithText(TextField, 'Reps feitas'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Senti dor nesta série'), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('esforço só aparece depois de "Detalhar esforço"', (tester) async {
    await abrirAjustar(tester, const Size(390, 844));
    expect(find.byType(Slider), findsNothing);
    await tester.tap(find.text('Detalhar esforço'));
    await tester.pump();
    expect(find.byType(Slider), findsOneWidget);
    await tester.tap(find.byTooltip('Remover esforço'));
    await tester.pump();
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('cabe sem rolar em 360×690 com letra 1,3x', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await abrirAjustar(tester, const Size(360, 690));
    expect(tester.takeException(), isNull);
    final salvar = find.text('Salvar série');
    expect(salvar, findsOneWidget);
    expect(tester.getRect(salvar).bottom, lessThanOrEqualTo(690));
  });

  testWidgets('escolher Dor marca esforço alto e salva', (tester) async {
    await abrirAjustar(tester, const Size(390, 844));
    await tester.tap(find.text('Dor'));
    await tester.pump();
    expect(find.byType(Slider), findsOneWidget);
    await tester.ensureVisible(find.text('Salvar série'));
    await tester.tap(find.text('Salvar série'));
    await pumpSheet(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Salvar série'), findsNothing);
    expect(find.textContaining('Série 1 registrada'), findsOneWidget);
  });
}
