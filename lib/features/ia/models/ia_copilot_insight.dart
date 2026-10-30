import '../copilot_insight_text.dart';

/// Insight do Copiloto — parse na borda API → modelo imutável.
class IaCopilotInsight {
  const IaCopilotInsight({
    required this.titulo,
    required this.tipo,
    required this.detalhe,
    this.recomendacao = '',
    this.status = 'READY',
  });

  final String titulo;
  final String tipo;
  /// O que os dados mostram.
  final String detalhe;

  /// O que o personal deve fazer.
  final String recomendacao;
  final String status;

  bool get ready => status.toUpperCase() == 'READY';

  factory IaCopilotInsight.fromJson(
    Map<String, dynamic> json, {
    int index = 0,
  }) {
    return IaCopilotInsight(
      titulo: copilotInsightTitulo(json, index),
      tipo: copilotInsightTipo(json),
      detalhe: copilotInsightDetalhe(json),
      recomendacao: copilotInsightRecomendacao(json),
      status: (json['status'] ?? 'READY').toString(),
    );
  }
}
