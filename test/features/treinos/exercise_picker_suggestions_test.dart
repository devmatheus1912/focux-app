import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/treinos/utils/exercise_picker_suggestions.dart';

void main() {
  group('curatedPickerSuggestions', () {
    test('prioriza termos comuns da biblioteca', () {
      final items = [
        Exercicio(id: 1, nome: 'Supino reto barra', curado: true),
        Exercicio(id: 2, nome: 'Agachamento livre', curado: true),
        Exercicio(id: 3, nome: 'Remada curvada', curado: true),
        Exercicio(id: 4, nome: 'Abducao maquina', curado: true),
      ];

      final suggestions = curatedPickerSuggestions(
        items,
        alreadyInTreinoIds: const {},
        limit: 3,
      );

      expect(suggestions.length, 3);
      expect(suggestions.first.nome, contains('Supino'));
    });

    test('prioriza exercícios recentes do personal', () {
      final items = [
        Exercicio(id: 1, nome: 'Supino reto barra'),
        Exercicio(id: 2, nome: 'Agachamento livre'),
        Exercicio(id: 99, nome: 'Abducao maquina'),
      ];

      final suggestions = curatedPickerSuggestions(
        items,
        alreadyInTreinoIds: const {},
        recentIds: const [99],
        limit: 2,
      );

      expect(suggestions.first.id, 99);
    });

    test('ignora exercícios já no treino', () {
      final items = [
        Exercicio(id: 1, nome: 'Supino reto barra'),
        Exercicio(id: 2, nome: 'Agachamento livre'),
      ];

      final suggestions = curatedPickerSuggestions(
        items,
        alreadyInTreinoIds: const {1},
        limit: 4,
      );

      expect(suggestions.any((e) => e.id == 1), isFalse);
      expect(suggestions.any((e) => e.id == 2), isTrue);
    });
  });
}
