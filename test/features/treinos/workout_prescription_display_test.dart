import 'package:flutter_test/flutter_test.dart';

import 'package:focux_app/features/treinos/utils/workout_prescription_display.dart';

void main() {
  test('formatActivePrescriptionLine monta hipertrofia padrão', () {
    expect(
      formatActivePrescriptionLine(
        presetLabel: 'Hipertrofia',
        series: '4',
        repeticoes: '8-12',
        descansoSegundos: '75',
      ),
      'Hipertrofia · 4×8-12 · 75s',
    );
  });

  test('formatActivePrescriptionLine inclui tipo de série', () {
    expect(
      formatActivePrescriptionLine(
        presetLabel: 'Força',
        series: '5',
        repeticoes: '3-6',
        descansoSegundos: '150',
        tipoSerie: 'SUPERSET',
      ),
      'Força · 5×3-6 · 150s · Superset',
    );
  });
}
