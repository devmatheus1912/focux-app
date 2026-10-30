import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _fonte(String caminho) => File(caminho).readAsStringSync();

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('uma porta só', () {
    test('a linha do perfil 360 se chama Ficha de treino', () {
      expect(_fonte('lib/l10n/app_pt.arb'), contains('"alunoResumoFichaTitulo": "Ficha de treino"'));
      expect(
        _fonte('lib/features/alunos/widgets/aluno360_ficha_card.dart'),
        allOf(contains('Aluno360FichaCard'), contains("'/alunos/\$alunoId/rotina'")),
      );
    });

    test('a lista do personal se chama Modelos de treino', () {
      expect(_fonte('lib/l10n/app_pt.arb'), contains('"treinosModelosTitulo": "Modelos de treino"'));
      final lista = _fonte(
        'lib/features/treinos/screens/modelos_de_treino_view.dart',
      );
      expect(lista, contains('treinosModelosTitulo'));
      expect(lista, isNot(contains("'Biblioteca'")));
    });
  });
}
