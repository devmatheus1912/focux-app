import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/data/checkin_series_pendentes.dart';
import 'package:focux_app/features/checkin/utils/checkin_series_fila.dart';
import 'package:focux_app/features/checkin/utils/checkin_sessao.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/checkin_screen_harness.dart';

class _RepoComServidor extends FakeCheckinRepo {
  int detalhes = 0;

  @override
  Future<ExecucaoTreino> detalhe(int execucaoId) async {
    detalhes++;
    return ExecucaoTreino.fromJson({
      'id': execucaoId,
      'treinoId': 7,
      'treinoNome': 'Do servidor',
      'status': 'EM_ANDAMENTO',
      'exercicios': const [],
    });
  }
}

CheckinSessao _sessao(
  CheckinRepository repo, {
  CheckinFilaResultado resultado = const CheckinFilaResultado(
    enviadas: [],
    rejeitadas: 0,
    restantes: [],
  ),
}) => CheckinSessao(
  repo: repo,
  fila: const CheckinSeriesPendentesStore(),
  enviarFila: () async => resultado,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'iniciar abre a sessão sem nada pendente quando a fila está vazia',
    () async {
      final estado = await _sessao(FakeCheckinRepo()).iniciar(7);

      expect(estado.execucao?.id, 1);
      expect(estado.pendentes, 0);
    },
  );

  test('fila sem recusa mantém a execução local sem ir ao servidor', () async {
    final repo = _RepoComServidor();
    final sessao = _sessao(repo);
    final base = (await sessao.iniciar(7)).execucao;

    final estado = await sessao.sincronizar(() => base);

    expect(estado.execucao?.treinoNome, 'Treino A');
    expect(repo.detalhes, 0);
  });

  test(
    'série recusada pela fila faz a execução voltar à do servidor',
    () async {
      final repo = _RepoComServidor();
      final sessao = _sessao(
        repo,
        resultado: const CheckinFilaResultado(
          enviadas: [],
          rejeitadas: 1,
          restantes: [],
        ),
      );
      final base = (await sessao.iniciar(7)).execucao;

      final estado = await sessao.sincronizar(() => base);

      expect(repo.detalhes, 1);
      expect(estado.execucao?.treinoNome, 'Do servidor');
      expect(estado.pendentes, 0);
    },
  );

  test('série marcada durante o envio não some', () async {
    final repo = _RepoComServidor();
    final base = (await _sessao(repo).iniciar(7)).execucao!;
    var atual = base;
    final sessao = CheckinSessao(
      repo: repo,
      fila: const CheckinSeriesPendentesStore(),
      enviarFila: () async {
        // O aluno marca uma série enquanto a fila sobe.
        atual = ExecucaoTreino.fromJson({
          'id': base.id,
          'treinoId': 7,
          'treinoNome': 'Marcada durante o envio',
          'status': 'EM_ANDAMENTO',
          'exercicios': const [],
        });
        return const CheckinFilaResultado(
          enviadas: [],
          rejeitadas: 0,
          restantes: [],
        );
      },
    );

    final estado = await sessao.sincronizar(() => atual);

    expect(estado.execucao?.treinoNome, 'Marcada durante o envio');
  });

  test('descartar avisa o servidor', () async {
    final repo = FakeCheckinRepo();
    await _sessao(repo).descartar(1);

    expect(repo.descartes, 1);
  });
}
