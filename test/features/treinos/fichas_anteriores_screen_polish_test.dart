import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ficha_historico_harness.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  test('as telas cumprem o contrato das telas', () {
    for (final arquivo in [
      'lib/features/treinos/screens/fichas_anteriores_screen.dart',
      'lib/features/treinos/screens/ficha_anterior_screen.dart',
    ]) {
      final fonte = File(arquivo).readAsStringSync();
      expect(fonte, contains('fxScreenA11yScope'), reason: arquivo);
      expect(fonte, contains('FxLoading'), reason: arquivo);
      expect(
        fonte,
        isNot(contains('CircularProgressIndicator')),
        reason: arquivo,
      );
    }
  });

  testWidgets('lista as fichas com período, motivo e resumo', (tester) async {
    await abrirHistorico(tester, [fichaRecomecada, fichaDoModelo]);

    expect(find.text('12/08 a 14/10'), findsOneWidget);
    expect(find.textContaining('Recomeçada'), findsOneWidget);
    expect(find.textContaining('2 sessões · 9 exercícios'), findsOneWidget);
    expect(find.text('Até 11/08'), findsOneWidget);
    expect(
      find.textContaining('Trocada pelo modelo Hipertrofia 4 dias'),
      findsOneWidget,
    );
  });

  testWidgets('sem fichas mostra o estado vazio', (tester) async {
    await abrirHistorico(tester, const []);

    expect(find.text('Nenhuma ficha anterior'), findsOneWidget);
    expect(
      find.text('Quando você trocar a ficha, a anterior fica guardada aqui.'),
      findsOneWidget,
    );
  });
}
