import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/transient_error.dart';
import '../../../core/cache/offline_cache.dart';
import '../../../core/media/fx_economia_de_dados.dart';
import '../models/treino_previa.dart';
import 'checkin_repository.dart';
import 'checkin_series_pendentes.dart';

/// Check-in sem internet (SPEC-checkin-offline).
///
/// - O pacote da semana (a prévia completa de cada treino) fica no aparelho.
/// - Sem rede, o treino abre numa **sessão local** com id negativo: as séries
///   vão para a mesma fila de sempre (presas ao id negativo) e não sobem
///   sozinhas.
/// - Concluída (ou "Já fiz"), a sessão local sobe inteira em
///   `POST /api/checkin/sessoes-offline` quando a rede volta, com a hora do
///   aparelho; o `clienteId` deixa o envio idempotente.
/// - Concluir uma sessão do servidor sem rede guarda a hora e manda depois.
/// Tudo sai no logout (`OfflineCache` e a chave da sessão local).

const _pacoteKey = 'checkin_pacote_semana';
const pacoteValidade = Duration(days: 7);

/// O pacote como veio da API; nulo se nunca baixou ou passou de 7 dias.
class PacoteDaSemana {
  const PacoteDaSemana({required this.treinos, required this.bloqueado});

  final List<TreinoPrevia> treinos;

  /// Mensalidade em atraso: sem internet também não abre (o iniciar recusaria).
  final bool bloqueado;

  TreinoPrevia? treino(int treinoId) => treinos.where((t) => t.treinoId == treinoId).firstOrNull;

  static PacoteDaSemana? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final lista = raw['treinos'];
    if (lista is! List) return null;
    final treinos = [
      for (final t in lista)
        if (t is Map) TreinoPrevia.fromJson(Map<String, dynamic>.from(t)),
    ];
    final bloqueado = lista.any((t) => t is Map && t['bloqueado'] == true);
    return PacoteDaSemana(treinos: treinos, bloqueado: bloqueado);
  }
}

abstract final class CheckinPacoteStore {
  static Future<void> salvar(Map<String, dynamic> json) => OfflineCache.put(_pacoteKey, json, ttl: pacoteValidade);

  static Future<PacoteDaSemana?> ler() async {
    try {
      return PacoteDaSemana.fromJson(await OfflineCache.get<dynamic>(_pacoteKey, ttl: pacoteValidade));
    } catch (_) {
      return null;
    }
  }
}

/// Baixa e guarda o pacote. Falha (sem rede) não apaga o que já estava.
Future<PacoteDaSemana?> atualizarPacoteDaSemana(CheckinRepository repo) async {
  try {
    final json = await repo.pacoteDaSemana();
    await CheckinPacoteStore.salvar(json);
    return PacoteDaSemana.fromJson(json);
  } catch (_) {
    return CheckinPacoteStore.ler();
  }
}

/// Pacote no aparelho e, no Wi-Fi, os vídeos do próximo treino.
Future<void> guardarParaSemInternet(CheckinRepository repo) async {
  final pacote = await atualizarPacoteDaSemana(repo);
  final proximo = pacote?.treinos.firstOrNull;
  if (proximo == null) return;
  await FxEconomiaDeDados.baixarParaDepois([for (final e in proximo.exercicios) e.videoUrl ?? '']);
}

/// Uma sessão feita sem internet, guardada até subir.
class SessaoLocal {
  const SessaoLocal({
    required this.chave,
    required this.clienteId,
    required this.treinoId,
    required this.treinoNome,
    required this.iniciadoEm,
    this.concluidoEm,
    this.jaFiz = false,
  });

  /// Id negativo da execução local (as séries da fila usam o mesmo).
  final int chave;
  final String clienteId;
  final int treinoId;
  final String treinoNome;
  final DateTime iniciadoEm;
  final DateTime? concluidoEm;
  final bool jaFiz;

  bool get pronta => concluidoEm != null;

  SessaoLocal concluir(DateTime quando, {bool jaFiz = false}) => SessaoLocal(
    chave: chave,
    clienteId: clienteId,
    treinoId: treinoId,
    treinoNome: treinoNome,
    iniciadoEm: iniciadoEm,
    concluidoEm: quando,
    jaFiz: jaFiz,
  );

  Map<String, dynamic> toJson() => {
    'chave': chave,
    'clienteId': clienteId,
    'treinoId': treinoId,
    'treinoNome': treinoNome,
    'iniciadoEm': iniciadoEm.toIso8601String(),
    if (concluidoEm != null) 'concluidoEm': concluidoEm!.toIso8601String(),
    'jaFiz': jaFiz,
  };

  static SessaoLocal? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final inicio = DateTime.tryParse('${raw['iniciadoEm']}');
    if (raw['chave'] is! int || raw['treinoId'] is! int || raw['clienteId'] is! String || inicio == null) {
      return null;
    }
    return SessaoLocal(
      chave: raw['chave'] as int,
      clienteId: raw['clienteId'] as String,
      treinoId: raw['treinoId'] as int,
      treinoNome: '${raw['treinoNome'] ?? 'Treino'}',
      iniciadoEm: inicio,
      concluidoEm: DateTime.tryParse('${raw['concluidoEm'] ?? ''}'),
      jaFiz: raw['jaFiz'] == true,
    );
  }
}

/// Sessões locais e "concluir" que ficaram sem rede (SharedPreferences).
class CheckinSessoesLocaisStore {
  const CheckinSessoesLocaisStore();

  static const prefKey = 'checkin_sessoes_locais_v1';
  static const _concluirKey = 'checkin_concluir_pendentes_v1';

  Future<List<SessaoLocal>> ler() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefKey);
    if (raw == null) return [];
    try {
      return [
        for (final s in jsonDecode(raw) as List)
          if (SessaoLocal.fromJson(s) case final sessao?) sessao,
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> _gravar(List<SessaoLocal> sessoes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, jsonEncode([for (final s in sessoes) s.toJson()]));
  }

  Future<void> salvar(SessaoLocal sessao) async {
    final todas = [for (final s in await ler()) if (s.chave != sessao.chave) s, sessao];
    await _gravar(todas);
  }

  Future<void> remover(int chave) async => _gravar([for (final s in await ler()) if (s.chave != chave) s]);

  /// A sessão local aberta deste treino (o app fechou no meio do treino).
  Future<SessaoLocal?> abertaDo(int treinoId) async =>
      (await ler()).where((s) => s.treinoId == treinoId && !s.pronta).firstOrNull;

  Future<SessaoLocal?> daChave(int chave) async => (await ler()).where((s) => s.chave == chave).firstOrNull;

  /// Concluir de sessão do servidor que ficou sem rede: execucaoId → hora.
  Future<Map<int, DateTime>> concluirPendentes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_concluirKey);
    if (raw == null) return {};
    try {
      final m = jsonDecode(raw) as Map;
      return {
        for (final e in m.entries)
          if (int.tryParse('${e.key}') case final id?)
            if (DateTime.tryParse('${e.value}') case final t?) id: t,
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _gravarConcluir(Map<int, DateTime> m) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_concluirKey, jsonEncode({for (final e in m.entries) '${e.key}': e.value.toIso8601String()}));
  }

  Future<void> concluirDepois(int execucaoId, DateTime quando) async =>
      _gravarConcluir({...await concluirPendentes(), execucaoId: quando});

  Future<void> concluido(int execucaoId) async =>
      _gravarConcluir({...await concluirPendentes()}..remove(execucaoId));

  static Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefKey);
    await prefs.remove(_concluirKey);
  }
}

/// UUID v4 para o `clienteId` (gerado no aparelho, sem dado da pessoa).
String novoClienteId([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

/// Execução montada do pacote: a mesma tela, com id negativo.
ExecucaoTreino execucaoLocal(TreinoPrevia p, SessaoLocal sessao) => ExecucaoTreino(
  id: sessao.chave,
  treinoId: p.treinoId,
  treinoNome: p.treinoNome,
  status: 'EM_ANDAMENTO',
  iniciadoEm: sessao.iniciadoEm.toIso8601String(),
  exercicios: [
    for (var i = 0; i < p.exercicios.length; i++)
      ExecucaoExercicio(
        id: sessao.chave * 1000 - i,
        treinoExercicioId: p.exercicios[i].treinoExercicioId,
        exercicioNome: p.exercicios[i].exercicioNome,
        gifUrl: p.exercicios[i].gifUrl,
        thumbnailUrl: p.exercicios[i].thumbnailUrl,
        videoUrl: p.exercicios[i].videoUrl,
        videoSource: p.exercicios[i].videoSource,
        licenseStatus: p.exercicios[i].licenseStatus,
        errosComuns: p.exercicios[i].errosComuns,
        contraindicacoes: p.exercicios[i].contraindicacoes,
        substitutos: p.exercicios[i].substitutos,
        series: p.exercicios[i].series ?? p.exercicios[i].seriesPrescritas.length,
        repeticoes: p.exercicios[i].repeticoes,
        cargaKg: p.exercicios[i].cargaKg,
        descansoSegundos: p.exercicios[i].descansoSegundos,
        observacoes: p.exercicios[i].observacoes,
        rpeAlvo: p.exercicios[i].rpeAlvo,
        seriesFeitas: 0,
        concluido: false,
        seriesPrescritas: p.exercicios[i].seriesPrescritas,
        metodo: p.exercicios[i].metodo,
      ),
  ],
);

/// Hora local sem fuso ("2026-11-16T19:40:00"): o backend lê como a de Brasília.
String _horaLocal(DateTime t) => t.toLocal().toIso8601String().split('.').first;

/// Corpo do `POST /api/checkin/sessoes-offline`.
Map<String, dynamic> corpoDaSessaoLocal(SessaoLocal s, List<CheckinSeriePendente> series) {
  final porExercicio = <int, List<CheckinSeriePendente>>{};
  for (final p in series.where((p) => p.execucaoId == s.chave)) {
    porExercicio.putIfAbsent(p.treinoExercicioId, () => []).add(p);
  }
  return {
    'clienteId': s.clienteId,
    'treinoId': s.treinoId,
    'iniciadoEm': _horaLocal(s.iniciadoEm),
    if (s.concluidoEm != null) 'concluidoEm': _horaLocal(s.concluidoEm!),
    'jaFiz': s.jaFiz,
    'exercicios': [
      for (final e in porExercicio.entries)
        {
          'treinoExercicioId': e.key,
          'series': [
            for (final p in e.value)
              {
                'numero': p.numero,
                if (p.cargaKg != null) 'cargaKg': p.cargaKg,
                if (p.repeticoes != null) 'repeticoes': p.repeticoes,
                if (p.feedback != null) 'feedback': p.feedback,
                if (p.rpe != null) 'rpe': p.rpe,
                'dor': p.dor,
              },
          ],
        },
    ],
  };
}

/// Sobe as sessões locais prontas e os "concluir" que ficaram sem rede.
/// Para no primeiro erro de rede; recusa do servidor (4xx) tira da lista.
/// Devolve quantas sessões subiram.
Future<int> sincronizarSessoesLocais({
  required CheckinRepository repo,
  CheckinSessoesLocaisStore store = const CheckinSessoesLocaisStore(),
  CheckinSeriesPendentesStore fila = const CheckinSeriesPendentesStore(),
}) async {
  var subiram = 0;
  for (final s in (await store.ler()).where((s) => s.pronta)) {
    try {
      await repo.sessaoOffline(corpoDaSessaoLocal(s, await fila.ler()));
      subiram++;
    } catch (e) {
      if (isTransientApiError(e)) return subiram;
    }
    await fila.removerDaExecucao(s.chave);
    await store.remover(s.chave);
  }
  for (final e in (await store.concluirPendentes()).entries) {
    try {
      await repo.concluir(e.key, concluidoEm: e.value);
      subiram++;
    } catch (err) {
      if (isTransientApiError(err)) return subiram;
    }
    await store.concluido(e.key);
  }
  return subiram;
}

