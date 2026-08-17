import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dunning/data/dunning_repository.dart';

void main() {
  test('DunningHomeBundle parses snapshot + falhas', () {
    final bundle = DunningHomeBundle.fromJson({
      'snapshot': {
        'total': 10,
        'abertas': 3,
        'recuperadas': 7,
        'recoveryRate': 70.0,
      },
      'falhas': [
        {
          'id': 1,
          'alunoId': 2,
          'contexto': 'ALUNO_MENSALIDADE',
          'motivo': 'Cartao recusado',
          'valor': 99.9,
          'tentativa': 1,
          'criadoEm': '2026-08-16T10:00:00',
        },
      ],
    });
    expect(bundle.snapshot.total, 10);
    expect(bundle.snapshot.abertas, 3);
    expect(bundle.snapshot.recuperadas, 7);
    expect(bundle.snapshot.recoveryRate, 70.0);
    expect(bundle.falhas, hasLength(1));
    expect(bundle.falhas.first.contexto, 'ALUNO_MENSALIDADE');
    expect(bundle.falhas.first.alunoId, 2);
    expect(bundle.falhas.first.motivo, 'Cartao recusado');
    expect(bundle.falhas.first.valor, 99.9);
  });

  test('DunningHomeBundle tolerates missing snapshot and falhas', () {
    final bundle = DunningHomeBundle.fromJson({});
    expect(bundle.snapshot.total, 0);
    expect(bundle.snapshot.abertas, 0);
    expect(bundle.snapshot.recoveryRate, 0);
    expect(bundle.falhas, isEmpty);
  });
}
