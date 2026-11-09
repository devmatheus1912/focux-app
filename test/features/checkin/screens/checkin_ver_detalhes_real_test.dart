

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/models/checkin_execucao_models.dart';
import 'package:focux_app/features/checkin/screens/historico_detalhe_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../support/checkin_screen_harness.dart';

/// "Ver detalhes" no fim do treino abre a tela de detalhe de verdade (o
/// teste antigo trocava ela por um texto e não pegava o travamento do iPhone).
class _RepoComDetalhe extends FakeCheckinRepo {
  _RepoComDetalhe() : super(feitas: [3, 3]);

  @override
  Future<ExecucaoTreino> detalhe(int execucaoId) async {
    // Antes de concluir, a execução pede o detalhe como o harness padrão.
    if (concluidos == 0) return super.detalhe(execucaoId);
    return _concluida(execucaoId);
  }

  ExecucaoTreino _concluida(int execucaoId) => ExecucaoTreino.fromJson({
    'id': execucaoId,
    'treinoId': 5,
    'treinoNome': 'C · Pernas',
    'status': 'CONCLUIDO',
    'iniciadoEm': '2026-11-08T01:55:00',
    'concluidoEm': '2026-11-08T04:27:00',
    'exercicios': [
      {
        'id': 10,
        'treinoExercicioId': 2,
        'exercicioNome': 'Agachamento',
        'series': 3,
        'repeticoes': '10',
        'cargaKg': null,
        'descansoSegundos': 75,
        'seriesFeitas': 3,
        'concluido': true,
      },
    ],
  });

  @override
  Future<SessaoEvolucaoDto> evolucaoSessao(int execucaoId) async =>
      SessaoEvolucaoDto.fromJson({'execucaoId': execucaoId});
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Ver detalhes abre o detalhe real sem travar', (tester) async {
    final repo = _RepoComDetalhe();
    await pumpCheckin(
      tester,
      repo,
      historico: (id) => HistoricoDetalheScreen(execucaoId: id),
    );

    await escolherNoMenuMais(tester, 'Finalizar treino');
    await pumpSheet(tester);
    await tester.tap(find.text('Ver detalhes'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);
    expect(find.text('Agachamento'), findsWidgets);
  });
}
