import '../utils/ia_progressao_carga_delta.dart';

int? _parseApiInt(Object? raw) {
  return switch (raw) {
    final int value => value,
    final num value => value.toInt(),
    final String value => int.tryParse(value),
    _ => null,
  };
}

class ProgressaoSugestao {
  const ProgressaoSugestao({
    required this.id,
    required this.alunoId,
    this.alunoNome,
    this.treinoExercicioId,
    this.exercicioBibliotecaId,
    required this.exercicio,
    required this.cargaAtual,
    required this.cargaSugerida,
    this.justificativa,
    this.deltaKg,
    this.aceita = false,
    this.criadoEm,
    this.seriesSugeridas,
    this.repeticoesSugeridas,
    this.status = statusPendente,
  });

  static const statusPendente = 'PENDENTE';
  static const statusNaoEncontrada = 'NAO_ENCONTRADA';

  final int id;
  final int alunoId;
  final String? alunoNome;
  final int? treinoExercicioId;
  final int? exercicioBibliotecaId;
  final String exercicio;
  final String cargaAtual;
  final String cargaSugerida;
  final String? justificativa;
  final double? deltaKg;
  final bool aceita;
  final DateTime? criadoEm;
  final int? seriesSugeridas;
  final String? repeticoesSugeridas;
  final String status;

  bool get naoEncontrada => status == statusNaoEncontrada;

  String? get deltaLabel =>
      formatProgressaoDeltaKg(deltaKg) ??
      computeProgressaoDeltaLabel(cargaAtual, cargaSugerida);

  factory ProgressaoSugestao.fromApi(Map<String, dynamic> json) {
    return ProgressaoSugestao(
      id: _parseApiInt(json['id'])!,
      alunoId: _parseApiInt(json['alunoId'])!,
      alunoNome: json['alunoNome'] as String?,
      treinoExercicioId: _parseApiInt(json['treinoExercicioId']),
      exercicioBibliotecaId: _parseApiInt(json['exercicioBibliotecaId']),
      exercicio: json['exercicio'] as String? ?? '—',
      cargaAtual: _resolveCargaText(
        json['cargaAtual'],
        json['cargaAnteriorKg'],
      ),
      cargaSugerida: _resolveCargaText(
        json['cargaSugerida'],
        json['cargaSugeridaKg'],
      ),
      justificativa:
          json['justificativa'] as String? ?? json['motivo'] as String?,
      deltaKg: _asDouble(json['deltaKg']),
      aceita: json['aceita'] == true,
      criadoEm: _parseDate(json['criadoEm']),
      seriesSugeridas: _parseApiInt(json['seriesSugeridas']),
      repeticoesSugeridas: json['repeticoesSugeridas'] as String?,
      status: json['status'] as String? ?? statusPendente,
    );
  }

  static double? _asDouble(Object? raw) {
    return switch (raw) {
      final num value => value.toDouble(),
      final String value => double.tryParse(value.replaceAll(',', '.')),
      _ => null,
    };
  }

  static String _resolveCargaText(Object? text, Object? kgFallback) {
    final primary = text?.toString().trim() ?? '';
    if (primary.isNotEmpty) return primary;
    final kg = _asDouble(kgFallback);
    if (kg == null) return '';
    final formatted =
        kg == kg.roundToDouble()
            ? kg.toStringAsFixed(0)
            : kg.toStringAsFixed(1).replaceAll('.', ',');
    return '$formatted kg';
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}

class ProgressaoAceitarResponse {
  const ProgressaoAceitarResponse({
    required this.cargaAplicada,
    this.treinoExercicioId,
    required this.mensagem,
  });

  final bool cargaAplicada;
  final int? treinoExercicioId;
  final String mensagem;

  factory ProgressaoAceitarResponse.fromApi(Map<String, dynamic> json) {
    return ProgressaoAceitarResponse(
      cargaAplicada: json['cargaAplicada'] == true,
      treinoExercicioId: _parseApiInt(json['treinoExercicioId']),
      mensagem: json['mensagem'] as String? ?? 'Sugestão processada.',
    );
  }
}

class ProgressaoAceitarTodasResponse {
  const ProgressaoAceitarTodasResponse({
    required this.aplicadas,
    required this.naoEncontradas,
  });

  final int aplicadas;
  final int naoEncontradas;

  factory ProgressaoAceitarTodasResponse.fromApi(Map<String, dynamic> json) {
    return ProgressaoAceitarTodasResponse(
      aplicadas: _parseApiInt(json['aplicadas']) ?? 0,
      naoEncontradas: _parseApiInt(json['naoEncontradas']) ?? 0,
    );
  }
}

/// Resumo do que a IA vai ler (treino ativo + execuções das últimas 4 semanas).
class ProgressaoContextoResumo {
  const ProgressaoContextoResumo({
    required this.treinos,
    required this.exercicios,
    required this.exerciciosComHistorico,
    required this.sessoes4Semanas,
  });

  final List<String> treinos;
  final int exercicios;
  final int exerciciosComHistorico;
  final int sessoes4Semanas;

  factory ProgressaoContextoResumo.fromApi(Map<String, dynamic> json) {
    final treinos = json['treinos'];
    return ProgressaoContextoResumo(
      treinos:
          treinos is List
              ? treinos.map((t) => t.toString()).toList(growable: false)
              : const [],
      exercicios: _parseApiInt(json['exercicios']) ?? 0,
      exerciciosComHistorico: _parseApiInt(json['exerciciosComHistorico']) ?? 0,
      sessoes4Semanas: _parseApiInt(json['sessoes4Semanas']) ?? 0,
    );
  }
}
