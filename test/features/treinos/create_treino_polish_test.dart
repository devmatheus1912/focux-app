import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/pt_br_display.dart';
import 'package:focux_app/features/treinos/utils/create_treino_logic.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('displayWorkoutName corrige Forca no preview do novo treino', () {
    expect(displayWorkoutName('Treino Forca'), 'Treino Força');
  });

  test('CreateTreinoLogic nivelLabel', () {
    expect(CreateTreinoLogic.nivelLabel(null), 'Em aberto');
    expect(CreateTreinoLogic.nivelLabel('INTERMEDIARIO'), 'Intermediário');
  });

  test('CreateTreinoLogic previewMeta', () {
    expect(
      CreateTreinoLogic.previewMeta(objetivo: 'Hipertrofia', nivel: 'INICIANTE'),
      'Hipertrofia · Iniciante',
    );
    expect(
      CreateTreinoLogic.previewMeta(objetivo: '', nivel: null),
      'Em aberto',
    );
  });

  test('create treino screen polish', () {
    final screen = readScreenSourceBundle(
      'lib/features/treinos/screens/create_treino_screen.dart',
    );

    expect(screen, contains("displayWorkoutName('Treino \${preset.title}')"));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('_PlanoBaseSummary'));
    expect(screen, contains('CreateTreinoLogic.planoBaseCaption'));
    expect(screen, isNot(contains('PLANO BASE')));
    expect(screen, contains('showCreateTreinoNivelPicker'));
    expect(screen, contains('exercicios/add'));
    expect(screen, contains('Scrollable.ensureVisible'));
    expect(screen, isNot(contains("label: 'Modelo \${preset.title}")));
    expect(screen, isNot(contains('BouncingScrollPhysics')));
    expect(screen, contains("label: 'Criar'"));
    expect(screen, contains("child: const Text('Cancelar')"));
    expect(screen, contains("loadingLabel: 'Criando…'"));
    expect(screen, contains('FxInsetPickerOption.list'));
    expect(screen, contains("label: 'Abrir biblioteca'"));
  });
}
