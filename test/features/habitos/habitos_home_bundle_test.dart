import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/habitos/data/habito_repository.dart';

void main() {
  test('HabitosHomeBundle parses habitos + compliance', () {
    final bundle = HabitosHomeBundle.fromJson({
      'habitos': [
        {
          'id': 1,
          'titulo': 'Beber água',
          'descricao': '2L/dia',
          'icone': '💧',
          'tipo': 'AGUA',
          'metaDiaria': 1,
          'metaSemanal': 7,
          'lembreteHora': '08:00',
          'feitosNaSemana': 0,
          'feitoHoje': false,
          'streakAtual': 0,
          'badgeSemana': false,
        },
      ],
      'compliance': [
        {
          'alunoId': 10,
          'alunoNome': 'Ana Silva',
          'checksSemana': 5,
          'compliancePct': 71,
        },
      ],
    });

    expect(bundle.habitos, hasLength(1));
    expect(bundle.habitos.first.titulo, 'Beber água');
    expect(bundle.habitos.first.metaSemanal, 7);
    expect(bundle.compliance, hasLength(1));
    expect(bundle.compliance.first.alunoNome, 'Ana Silva');
    expect(bundle.compliance.first.compliancePct, 71);
  });

  test('HabitosHomeBundle tolerates missing lists', () {
    final bundle = HabitosHomeBundle.fromJson({});
    expect(bundle.habitos, isEmpty);
    expect(bundle.compliance, isEmpty);
  });
}
