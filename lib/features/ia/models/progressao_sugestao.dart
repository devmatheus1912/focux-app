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
  });

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

  String? get deltaLabel =>
      _deltaFromApi(deltaKg) ??
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
    return '${formatted}kg';
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static String? _deltaFromApi(double? value) {
    if (value == null || value.abs() < 0.01) return null;
    final sign = value > 0 ? '+' : '';
    final abs = value.abs();
    final formatted =
        abs == abs.roundToDouble()
            ? abs.toStringAsFixed(0)
            : abs.toStringAsFixed(1).replaceAll('.', ',');
    return '$sign$formatted kg';
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
