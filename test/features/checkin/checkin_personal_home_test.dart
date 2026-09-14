import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/models/checkin_personal_home.dart';

void main() {
  test('fromJson materializa hoje e semana', () {
    final bundle = CheckinPersonalHomeBundle.fromJson({
      'checkinsHoje': 1,
      'hoje': [
        {
          'id': 9,
          'alunoId': 3,
          'alunoNome': 'Ana',
          'treinoNome': 'Full body',
          'fotoUrl': null,
          'iniciadoEm': '2026-08-31T10:00:00',
        },
      ],
      'semana': [],
      'itens': [
        {'id': 9, 'alunoId': 3, 'alunoNome': 'Ana', 'treinoNome': 'Full body'},
      ],
      'page': 0,
      'totalItens': 1,
      'hasNext': false,
      'pendentes': [
        {'alunoId': 4, 'alunoNome': 'Bia', 'treinoId': 2, 'treinoNome': 'A'},
      ],
    });
    expect(bundle.checkinsHoje, 1);
    expect(bundle.hoje.single.alunoId, 3);
    expect(bundle.hoje.single.treinoNome, 'Full body');
    expect(bundle.semana, isEmpty);
    expect(bundle.itens.single.alunoId, 3);
    expect(bundle.hasNext, isFalse);
    expect(bundle.pendentes.single.alunoId, 4);
    expect(bundle.pendentes.single.treinoId, 2);
  });
}
