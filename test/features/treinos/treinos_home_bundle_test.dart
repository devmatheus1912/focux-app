import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';

void main() {
  test('TreinosHomeBundle parses slim list + resumo', () {
    final bundle = TreinosHomeBundle.fromJson({
      'treinos': [
        {
          'id': 1,
          'nome': 'A — Peito',
          'isTemplate': false,
          'exerciciosCount': 12,
          'seriesTotal': 36,
          'pronto': true,
        },
      ],
      'resumo': {
        'totalPlanos': 1,
        'prontos': 1,
        'emMontagem': 0,
        'templates': 0,
        'totalExercicios': 12,
      },
      'uiHints': {
        'libraryCaption': '1 pronto · 12 exercícios',
        'createCtaLabel': 'Criar treino',
      },
    });
    expect(bundle.treinos, hasLength(1));
    expect(bundle.treinos.first.exerciciosCount, 12);
    expect(bundle.treinos.first.seriesTotal, 36);
    expect(bundle.treinos.first.pronto, isTrue);
    expect(bundle.resumo.prontos, 1);
    expect(bundle.uiHints.libraryCaption, '1 pronto · 12 exercícios');
    expect(bundle.uiHints.createCtaLabel, 'Criar treino');
  });
}
