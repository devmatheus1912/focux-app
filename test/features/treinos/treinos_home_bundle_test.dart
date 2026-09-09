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
    expect(bundle.hasNext, isFalse);
    expect(bundle.totalElements, 1);
  });

  test('TreinosHomeBundle lê hasNext e totalElements', () {
    final bundle = TreinosHomeBundle.fromJson({
      'treinos': const [],
      'resumo': {
        'totalPlanos': 80,
        'prontos': 70,
        'emMontagem': 10,
        'templates': 2,
        'totalExercicios': 400,
      },
      'page': 1,
      'size': 40,
      'totalElements': 80,
      'hasNext': true,
    });
    expect(bundle.page, 1);
    expect(bundle.size, 40);
    expect(bundle.totalElements, 80);
    expect(bundle.hasNext, isTrue);
    expect(bundle.resumo.totalPlanos, 80);
  });
}
