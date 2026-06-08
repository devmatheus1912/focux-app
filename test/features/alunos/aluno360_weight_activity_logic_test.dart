import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_weight_activity_card.dart';

void main() {
  group('resolveWeightSeriesForAluno', () {
    test('returns avaliacoes when present', () {
      expect(
        resolveWeightSeriesForAluno([70.0, 71.5, 72.0], 72.0),
        [70.0, 71.5, 72.0],
      );
    });

    test('duplicates current peso when no historico', () {
      expect(
        resolveWeightSeriesForAluno(const [], 68.5),
        [68.5, 68.5],
      );
    });

    test('returns empty when no data', () {
      expect(resolveWeightSeriesForAluno(const [], null), isEmpty);
    });
  });
}
