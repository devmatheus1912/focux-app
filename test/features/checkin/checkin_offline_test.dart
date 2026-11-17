import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/cache/offline_cache.dart';
import 'package:focux_app/features/checkin/data/checkin_offline.dart';
import 'package:focux_app/features/checkin/data/checkin_series_pendentes.dart';
import 'package:focux_app/features/checkin/utils/checkin_series_fila.dart';
import 'package:focux_app/features/checkin/utils/checkin_sessao.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/checkin_screen_harness.dart';

/// Check-in sem internet (SPEC-checkin-offline).
Map<String, dynamic> _pacote({bool bloqueado = false}) => {
  'treinos': [
    {
      'treinoId': 7,
      'treinoNome': 'A · Empurrar',
      'bloqueado': bloqueado,
      'exercicios': [
        {
          'treinoExercicioId': 2,
          'exercicioNome': 'Supino',
          'series': 2,
          'repeticoes': '10',
          'metodo': {'tecnica': 'DROPSET', 'quedas': 2},
          'seriesPrescritas': [
            {'numero': 1, 'repeticoes': '10', 'papel': 'VALIDA'},
            {'numero': 2, 'repeticoes': '10', 'papel': 'VALIDA', 'tecnica': 'DROPSET'},
          ],
        },
      ],
    },
  ],
};

CheckinSessao _sessao(FakeCheckinRepo repo) => CheckinSessao(
  repo: repo,
  fila: const CheckinSeriesPendentesStore(),
  enviarFila: () async => const CheckinFilaResultado(enviadas: [], rejeitadas: 0, restantes: []),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final agora = DateTime(2026, 11, 16, 19, 40);

  test('sem internet e com o pacote: abre a sessão local com o método do personal', () async {
    await OfflineCache.put('checkin_pacote_semana', _pacote(), ttl: pacoteValidade);
    final repo = FakeCheckinRepo()..iniciarOffline = true;

    final estado = await _sessao(repo).iniciar(7, agora: () => agora);

    final ex = estado.execucao!;
    expect(ex.id, isNegative);
    expect(ex.treinoNome, 'A · Empurrar');
    expect(ex.exercicios.single.seriesPrescritas.last.tecnica, 'DROPSET');
    // Reabrir o app no meio do treino retoma a mesma sessão local.
    final deNovo = await _sessao(repo).iniciar(7, agora: () => agora.add(const Duration(minutes: 5)));
    expect(deNovo.execucao!.id, ex.id);
  });

  test('sem pacote, ou com mensalidade em atraso, o erro de rede segue como antes', () async {
    final repo = FakeCheckinRepo()..iniciarOffline = true;
    await expectLater(_sessao(repo).iniciar(7), throwsA(anything));
    await OfflineCache.put('checkin_pacote_semana', _pacote(bloqueado: true), ttl: pacoteValidade);
    await expectLater(_sessao(repo).iniciar(7), throwsA(anything));
  });

  test('série da sessão local fica no aparelho; concluir sobe a sessão inteira uma vez', () async {
    await OfflineCache.put('checkin_pacote_semana', _pacote(), ttl: pacoteValidade);
    final repo = FakeCheckinRepo()
      ..iniciarOffline = true
      ..offline = true;
    final sessao = _sessao(repo);
    final id = (await sessao.iniciar(7, agora: () => agora)).execucao!.id!;

    final r = await checkinRegistrarSerie(
      serie: CheckinSeriePendente(execucaoId: id, treinoExercicioId: 2, numero: 1, cargaKg: 40, repeticoes: '10'),
      store: const CheckinSeriesPendentesStore(),
      enviar: checkinEnvioPelo(repo),
      sessaoAtiva: () async => true,
    );
    expect(r, isA<CheckinRegistroNaFila>());
    expect(repo.registros, 0, reason: 'série local não tenta a API');

    // Sem rede no concluir: fica pronta no aparelho.
    await sessao.concluir(id, agora: () => agora.add(const Duration(minutes: 50)));
    expect(repo.sessoesOffline, isEmpty);
    expect((await const CheckinSessoesLocaisStore().ler()).single.pronta, isTrue);

    // A rede voltou: sobe uma vez, com as séries e a hora do aparelho.
    repo.offline = false;
    expect(await sincronizarSessoesLocais(repo: repo), 1);
    expect(await sincronizarSessoesLocais(repo: repo), 0);
    final corpo = repo.sessoesOffline.single;
    expect(corpo['treinoId'], 7);
    expect(corpo['concluidoEm'], '2026-11-16T20:30:00');
    expect(((corpo['exercicios'] as List).single as Map)['series'], hasLength(1));
    expect(await const CheckinSeriesPendentesStore().ler(), isEmpty);
  });

  test('concluir sessão do servidor sem rede guarda a hora e manda depois', () async {
    final repo = FakeCheckinRepo()..offline = true;
    final conclusao = await _sessao(repo).concluir(1, agora: () => agora);
    expect(conclusao.concluida, isNull);
    expect(await const CheckinSessoesLocaisStore().concluirPendentes(), {1: agora});

    repo.offline = false;
    await sincronizarSessoesLocais(repo: repo);
    expect(await const CheckinSessoesLocaisStore().concluirPendentes(), isEmpty);
  });

  test('"Já fiz" sem internet vira sessão local pronta', () async {
    final repo = FakeCheckinRepo()..offline = true;
    await const CheckinSessoesLocaisStore().salvar(SessaoLocal(
      chave: -1, clienteId: novoClienteId(), treinoId: 7, treinoNome: 'A', iniciadoEm: agora,
    ).concluir(agora, jaFiz: true));
    repo.offline = false;
    await sincronizarSessoesLocais(repo: repo);
    expect(repo.sessoesOffline.single['jaFiz'], isTrue);
  });

  test('clienteId é um UUID v4', () {
    expect(novoClienteId(), matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
  });
}
