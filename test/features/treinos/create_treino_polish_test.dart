import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/pt_br_display.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('displayWorkoutName corrige Forca no preview do novo treino', () {
    expect(displayWorkoutName('Treino Forca'), 'Treino Força');
  });

  test('create treino screen polish', () {
    final screen = readScreenSourceBundle(
      'lib/features/treinos/screens/create_treino_screen.dart',
    );

    expect(screen, contains('displayWorkoutName(_nomeCtrl.text.trim())'));
    expect(screen, contains('Deslize para ver mais modelos'));
    expect(screen, contains('BouncingScrollPhysics'));
    expect(screen, contains('exercicios/add'));
    expect(screen, contains('Scrollable.ensureVisible'));
    expect(screen, contains("label: 'Modelo \${preset.title}"));
    expect(screen, contains("label: 'Nível \${_niveisLabel[i]}'"));
    expect(screen, contains("label: loading ? 'Criando treino' : 'Criar treino'"));
  });
}
