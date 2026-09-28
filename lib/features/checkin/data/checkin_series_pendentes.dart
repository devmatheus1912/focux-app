import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Série registrada sem conexão, esperando reenvio. O backend faz upsert por
/// (exercício, número), então reenviar a mesma série é seguro.
class CheckinSeriePendente {
  final int execucaoId;
  final int treinoExercicioId;
  final int numero;
  final double? cargaKg;
  final String? repeticoes;
  final String? feedback;
  final int? rpe;
  final bool dor;

  const CheckinSeriePendente({
    required this.execucaoId,
    required this.treinoExercicioId,
    required this.numero,
    this.cargaKg,
    this.repeticoes,
    this.feedback,
    this.rpe,
    this.dor = false,
  });

  bool mesmaSerie(CheckinSeriePendente o) =>
      o.execucaoId == execucaoId &&
      o.treinoExercicioId == treinoExercicioId &&
      o.numero == numero;

  Map<String, dynamic> toJson() => {
    'execucaoId': execucaoId,
    'treinoExercicioId': treinoExercicioId,
    'numero': numero,
    'cargaKg': cargaKg,
    'repeticoes': repeticoes,
    'feedback': feedback,
    'rpe': rpe,
    'dor': dor,
  };

  static CheckinSeriePendente? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final execucaoId = raw['execucaoId'];
    final treinoExercicioId = raw['treinoExercicioId'];
    final numero = raw['numero'];
    if (execucaoId is! int || treinoExercicioId is! int || numero is! int) {
      return null;
    }
    final carga = raw['cargaKg'];
    final rpe = raw['rpe'];
    return CheckinSeriePendente(
      execucaoId: execucaoId,
      treinoExercicioId: treinoExercicioId,
      numero: numero,
      cargaKg: carga is num ? carga.toDouble() : null,
      repeticoes: raw['repeticoes'] as String?,
      feedback: raw['feedback'] as String?,
      rpe: rpe is int ? rpe : null,
      dor: raw['dor'] == true,
    );
  }
}

/// Fila local das séries sem conexão. Limpa no logout (`SessionInvalidator`).
class CheckinSeriesPendentesStore {
  const CheckinSeriesPendentesStore();

  static const prefKey = 'checkin_series_pendentes_v1';

  Future<List<CheckinSeriePendente>> ler() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(CheckinSeriePendente.fromJson)
          .whereType<CheckinSeriePendente>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// A mesma série substitui a anterior e vai para o fim da fila.
  Future<void> adicionar(CheckinSeriePendente serie) async {
    final atual = await ler();
    await _salvar([...atual.where((p) => !p.mesmaSerie(serie)), serie]);
  }

  /// Remove só se o conteúdo não mudou: uma versão nova registrada durante o
  /// envio continua na fila.
  Future<void> remover(CheckinSeriePendente serie) async {
    final atual = await ler();
    final alvo = jsonEncode(serie.toJson());
    await _salvar(atual.where((p) => jsonEncode(p.toJson()) != alvo).toList());
  }

  /// Execução descartada: as séries dela não têm mais para onde ir.
  Future<void> removerDaExecucao(int execucaoId) async {
    final atual = await ler();
    await _salvar(atual.where((p) => p.execucaoId != execucaoId).toList());
  }

  static Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefKey);
  }

  Future<void> _salvar(List<CheckinSeriePendente> fila) async {
    final prefs = await SharedPreferences.getInstance();
    if (fila.isEmpty) {
      await prefs.remove(prefKey);
      return;
    }
    await prefs.setString(
      prefKey,
      jsonEncode(fila.map((p) => p.toJson()).toList()),
    );
  }
}
