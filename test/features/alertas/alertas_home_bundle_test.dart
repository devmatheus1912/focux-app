import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alertas/data/alertas_repository.dart';

void main() {
  test('AlertasHomeBundle parses riscos + configuracao', () {
    final bundle = AlertasHomeBundle.fromJson({
      'riscos': [
        {
          'alunoId': 10,
          'alunoNome': 'Ana Silva',
          'score': 3,
          'motivos': ['Sem treino há 12 dias'],
          'diasSemTreino': 12,
          'aderenciaPercent': 40.0,
        },
      ],
      'configuracao': {'diasSemTreino': 7, 'aderenciaMinima': 60},
    });

    expect(bundle.riscos, hasLength(1));
    expect(bundle.riscos.first.alunoNome, 'Ana Silva');
    expect(bundle.riscos.first.score, 3);
    expect(bundle.riscos.first.diasSemTreino, 12);
    expect(bundle.configuracao.diasSemTreino, 7);
    expect(bundle.configuracao.aderenciaMinima, 60);
  });

  test('AlertasHomeBundle tolerates missing riscos and configuracao', () {
    final bundle = AlertasHomeBundle.fromJson({});
    expect(bundle.riscos, isEmpty);
    expect(bundle.configuracao.diasSemTreino, 7);
    expect(bundle.configuracao.aderenciaMinima, 60);
  });
}
