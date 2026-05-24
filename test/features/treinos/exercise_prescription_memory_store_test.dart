import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/data/exercise_prescription_memory.dart';
import 'package:focux_app/features/treinos/data/exercise_prescription_memory_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExercisePrescriptionMemoryStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('salva e carrega última prescrição', () async {
      const memory = ExercisePrescriptionMemory(
        presetId: 'strength',
        series: 4,
        repeticoes: '6-8',
        descansoSegundos: 120,
        tipoSerie: 'NORMAL',
        cargaKg: 80,
        observacoes: 'Controlar descida',
      );

      await ExercisePrescriptionMemoryStore.save(memory);
      final loaded = await ExercisePrescriptionMemoryStore.load();

      expect(loaded?.presetId, 'strength');
      expect(loaded?.series, 4);
      expect(loaded?.repeticoes, '6-8');
      expect(loaded?.descansoSegundos, 120);
      expect(loaded?.cargaKg, 80);
      expect(loaded?.observacoes, 'Controlar descida');
    });
  });
}
