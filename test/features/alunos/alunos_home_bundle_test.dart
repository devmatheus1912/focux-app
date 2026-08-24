import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';

void main() {
  test('AlunosHomeBundle parses alunos + stats + config', () {
    final bundle = AlunosHomeBundle.fromJson({
      'alunos': [
        {
          'id': 1,
          'nome': 'Ana',
          'email': 'ana@test.com',
          'status': 'ATIVO',
          'inadimplente': false,
          'emRisco': false,
        },
      ],
      'stats': {
        'total': 1,
        'totalAtivos': 1,
        'totalInadimplentes': 0,
        'totalRiscoAlto': 0,
        'totalConvites': 0,
        'totalContatoHoje': 1,
      },
      'alertasConfig': {'diasSemTreino': 7, 'aderenciaMinima': 50},
      'planoFeatures': {
        'plano': 'PRO',
        'features': {
          'financeiro': true,
          'agenda': true,
          'relatorios': true,
          'whiteLabel': false,
          'iaCopiloto': true,
          'migracaoFoto': false,
        },
      },
    });
    expect(bundle.alunos, hasLength(1));
    expect(bundle.alunos.first.nome, 'Ana');
    expect(bundle.stats.totalAtivos, 1);
    expect(bundle.stats.totalContatoHoje, 1);
    expect(bundle.alertasConfig.diasSemTreino, 7);
    expect(bundle.planoFeatures, isNotNull);
  });
}
