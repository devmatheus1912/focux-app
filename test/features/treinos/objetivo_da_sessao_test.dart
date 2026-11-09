import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/data/workout_builder_preset.dart';

/// Objetivo da sessão (`treinos.objetivo`) ↔ preset da prescrição.
void main() {
  test('objetivo gravado vira preset; texto antigo conta como sem objetivo', () {
    expect(presetIdDoObjetivo('HIPERTROFIA'), 'hypertrophy');
    expect(presetIdDoObjetivo('forca'), 'strength');
    expect(presetIdDoObjetivo('RESISTENCIA'), 'endurance');
    expect(presetIdDoObjetivo('Emagrecimento e saúde'), isNull);
    expect(presetIdDoObjetivo(null), isNull);
  });

  test('ida e volta entre preset e valor da API', () {
    for (final p in workoutBuilderPresets) {
      expect(presetIdDoObjetivo(objetivoDoPreset(p.id)), p.id);
    }
  });

  test('efeito escrito com espaço antes do s', () {
    expect(efeitoDoPreset(workoutBuilderPresetById('hypertrophy')), '4 × 8-12 · 75 s');
  });
}
