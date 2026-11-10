import '../copilot_insight_text.dart';

/// Insight do Copiloto — parse na borda API → modelo imutável.
class IaCopilotInsight {
  const IaCopilotInsight({
    required this.titulo,
    required this.tipo,
    required this.detalhe,
    this.recomendacao = '',
    this.status = 'READY',
    this.tipoAcao,
    this.acaoLabel,
    this.mensagemSugerida,
  });

  /// Ação que esta recomendação oferece (`CARGA`, `MEDIDA`, `TREINO`…);
  /// nulo = sem botão.
  final String? tipoAcao;

  /// Verbo do botão ("Ajustar cargas").
  final String? acaoLabel;

  /// Texto pronto quando a ação é mandar mensagem ao aluno.
  final String? mensagemSugerida;

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
      tipoAcao: json['tipoAcao'] as String?,
      acaoLabel: json['acaoLabel'] as String?,
      mensagemSugerida: json['mensagemSugerida'] as String?,
    );
  }
}
