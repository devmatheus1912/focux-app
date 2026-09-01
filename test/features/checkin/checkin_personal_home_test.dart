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
    });
    expect(bundle.checkinsHoje, 1);
    expect(bundle.hoje.single.alunoId, 3);
    expect(bundle.hoje.single.treinoNome, 'Full body');
    expect(bundle.semana, isEmpty);
  });
}
