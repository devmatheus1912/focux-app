import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/nps/data/nps_repository.dart';

void main() {
  test('NpsHomeBundle parses resumo + recentes', () {
    final bundle = NpsHomeBundle.fromJson({
      'resumo': {
        'total': 10,
        'npsScore': 50.0,
        'media': 8.5,
        'promotores': 5,
        'detratores': 1,
        'neutros': 4,
      },
      'recentes': [
        {
          'id': 1,
          'alunoId': 2,
          'alunoNome': 'Ana',
          'score': 9,
          'comentario': 'Ótimo',
          'criadoEm': '2026-08-16T10:00:00',
        },
      ],
    });
    expect(bundle.resumo.total, 10);
    expect(bundle.resumo.npsScore, 50.0);
    expect(bundle.resumo.promotores, 5);
    expect(bundle.recentes, hasLength(1));
    expect(bundle.recentes.first.alunoNome, 'Ana');
    expect(bundle.recentes.first.score, 9);
    expect(bundle.recentes.first.alunoId, 2);
  });

  test('NpsHomeBundle tolerates missing resumo and recentes', () {
    final bundle = NpsHomeBundle.fromJson({});
    expect(bundle.resumo.total, 0);
    expect(bundle.recentes, isEmpty);
  });
}
