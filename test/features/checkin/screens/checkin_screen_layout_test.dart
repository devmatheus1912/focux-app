import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../support/checkin_screen_harness.dart';

/// Execução em três zonas: o essencial cabe sem rolar e o menu ⋯ guarda o resto.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> abrir(WidgetTester tester, Size tela, {double escala = 1}) async {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpCheckin(tester, FakeCheckinRepo(), tela: tela);
  }

  for (final (nome, tela, escala) in [
    ('390×844', const Size(390, 844), 1.0),
    ('360×690 com letra 1,3x', const Size(360, 690), 1.3),
  ]) {
    testWidgets('em $nome nome, campos e Registrar aparecem juntos, sem rolar', (
      tester,
    ) async {
      await abrir(tester, tela, escala: escala);
      expect(tester.takeException(), isNull);
      final registrar = find.text('Registrar série');
      expect(registrar, findsOneWidget);
      expect(find.text('kg'), findsWidgets);
      final alturaTela = tela.height;
      expect(tester.getRect(registrar).bottom, lessThanOrEqualTo(alturaTela));
      // nada do corpo da execução rola: só a mídia cede espaço
      expect(
        find.descendant(
          of: find.byType(Scaffold).first,
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
    });
  }

  testWidgets('só há um botão principal na base: Mais e Finalizar ficam no ⋯', (
    tester,
  ) async {
    await abrir(tester, const Size(390, 844));
    expect(find.text('Mais'), findsNothing);
    expect(find.text('Finalizar treino'), findsNothing);
    expect(find.byTooltip('Mais'), findsOneWidget);
  });

  for (final largura in [320.0, 390.0, 430.0]) {
    testWidgets('carga fica em uma linha em ${largura.toInt()} dp', (
      tester,
    ) async {
      await pumpCheckin(
        tester,
        FakeCheckinRepo(),
        tela: Size(largura, 900),
      );
      expect(tester.takeException(), isNull);
      final carga = find.text('20');
      expect(carga, findsOneWidget);
      expect(tester.getSize(carga).height, lessThan(80));
    });
  }
}
