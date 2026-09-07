import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';

void main() {
  test('AlunoPerfilHomeBundle parses aluno + medidas', () {
    final bundle = AlunoPerfilHomeBundle.fromJson({
      'aluno': {
        'id': 7,
        'nome': 'Ana Souza',
        'email': 'ana@focux.app',
        'status': 'ATIVO',
        'objetivo': 'Hipertrofia',
        'peso': 62.5,
        'altura': 1.65,
      },
      'medidas': [
        {'id': 3, 'data': '2026-08-10', 'peso': 62.5, 'cintura': 70.0},
      ],
      'completionPercent': 71,
    });

    expect(bundle.completionPercent, 71);
    expect(bundle.aluno.id, 7);
    expect(bundle.aluno.nome, 'Ana Souza');
    expect(bundle.aluno.peso, 62.5);
    expect(bundle.medidas, hasLength(1));
    expect(bundle.medidas.first.peso, 62.5);
    expect(bundle.medidas.first.cintura, 70.0);
  });

  test('AlunoPerfilHomeBundle tolerates missing medidas', () {
    final bundle = AlunoPerfilHomeBundle.fromJson({
      'aluno': {
        'id': 7,
        'nome': 'Ana Souza',
        'email': 'ana@focux.app',
        'status': 'ATIVO',
      },
    });

    expect(bundle.aluno.id, 7);
    expect(bundle.medidas, isEmpty);
    expect(bundle.completionPercent, isNull);
  });
}
