import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/utils/add_exercise_prescription_input.dart';

void main() {
  group('resolveAddExercisePrescription', () {
    AddExercisePrescriptionInput baseInput({
      String tipoSerie = 'NORMAL',
      String grupo = '1',
    }) {
      final resolved = resolveAddExercisePrescription(
        seriesText: '4',
        repeticoesText: '8-12',
        descansoText: '75',
        cargaText: '',
        observacoesText: 'Controle',
        tipoSerie: tipoSerie,
        grupoSupersetText: grupo,
      );
      expect(resolved.error, isNull);
      return resolved.values!;
    }

    test('aceita prescrição válida', () {
      final input = baseInput();
      expect(input.series, 4);
      expect(input.descansoSegundos, 75);
      expect(input.repeticoes, '8-12');
    });

    test('rejeita séries fora da faixa', () {
      final resolved = resolveAddExercisePrescription(
        seriesText: '25',
        repeticoesText: '8-12',
        descansoText: '75',
        cargaText: '',
        observacoesText: '',
        tipoSerie: 'NORMAL',
        grupoSupersetText: '1',
      );
      expect(resolved.values, isNull);
      expect(resolved.error, contains('1 e 20'));
    });

    test('exige grupo de superset', () {
      final resolved = resolveAddExercisePrescription(
        seriesText: '4',
        repeticoesText: '8-12',
        descansoText: '75',
        cargaText: '',
        observacoesText: '',
        tipoSerie: 'SUPERSET',
        grupoSupersetText: '',
      );
      expect(resolved.values, isNull);
      expect(resolved.error, isNotNull);
    });
  });
}
