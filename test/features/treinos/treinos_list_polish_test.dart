import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/pt_br_display.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  group('displayWorkoutName', () {
    test('corrige Forca para Força no card da biblioteca', () {
      expect(displayWorkoutName('Treino Forca'), 'Treino Força');
    });
  });

  test('treinos list sheet usa scroll e microcopy', () {
    final screen = [
      readScreenSourceBundle(
        'lib/features/treinos/screens/treinos_list_screen.dart',
      ),
      File(
        'lib/features/treinos/utils/treinos_list_labels.dart',
      ).readAsStringSync(),
    ].join('\n');

    expect(screen, contains('isScrollControlled: true'));
    expect(screen, contains('SingleChildScrollView'));
    expect(screen, contains('maxHeight: maxHeight'));
    expect(screen, contains('Atribuir a um aluno'));
    expect(screen, contains('control_point_duplicate_rounded'));
    expect(screen, contains('assignment_ind_rounded'));
    expect(screen, contains('displayWorkoutName(treino.nome)'));
    expect(screen, contains('TreinosListLabels.libraryCaption'));
    expect(screen, contains('segure para selecionar'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showTreinosListHelpSheet'));
    expect(
      File(
        'lib/features/treinos/widgets/treinos_list_help_sheet.dart',
      ).readAsStringSync(),
      contains('showFxHelpSheet'),
    );
    expect(screen, contains('useRootNavigator: true'));
    expect(screen, contains('_TreinosBulkBar'));
    expect(screen, contains('Selecionar todos'));
    expect(screen, contains('TreinosListLabels.deleteTitle'));
    expect(screen, contains('Ações do treino'));
    expect(screen, contains('TreinoHomeSheetSurface'));
    expect(screen, contains('TreinoSheetChromeHeader'));
    expect(screen, contains('treino_home_sheet.dart'));
    expect(screen, contains('ConstrainedBox('));
    expect(screen, isNot(contains('Ações em lote')));
    expect(screen, isNot(contains('Abra, atribua ou replique este plano')));
    expect(
      screen,
      isNot(contains('Histórico e execuções antigas não são apagados')),
    );
    expect(screen, isNot(contains('Biblioteca sob controle')));
    expect(screen, isNot(contains('Operações da biblioteca')));
    expect(screen, isNot(contains('LinearProgressIndicator')));
    expect(screen, isNot(contains('exerciciosCount * 5')));
    expect(screen, contains('TreinosListLabels.prettyField'));
    expect(screen, isNot(contains('_ptLabel(')));
    expect(screen, contains('ProductEvents.treinosViewed'));
    expect(screen, contains('ProductEvents.treinosTtv'));
    expect(screen, contains('ProductEvents.treinosRefreshed'));
    expect(screen, contains('ProductEvents.treinosSearchUsed'));
    expect(screen, contains('ProductEvents.treinosHelpOpened'));
    expect(screen, contains('ProductEvents.treinosCreateTapped'));
    expect(screen, contains('ProductEvents.treinosActionOpened'));
    expect(screen, contains('ProductEvents.treinosAssigned'));
    expect(screen, contains('ProductEvents.treinosCloned'));
    expect(screen, contains('ProductEvents.treinosDuplicated'));
    expect(screen, contains('ProductEvents.treinosBulkOpened'));
    expect(screen, contains('ProductEvents.treinosDeleted'));
  });
}
