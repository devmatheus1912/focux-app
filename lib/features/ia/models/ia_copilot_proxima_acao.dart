/// Próxima ação do Copiloto IA — parse na borda API → modelo imutável.
class IaCopilotProximaAcao {
  const IaCopilotProximaAcao({
    required this.acao,
    required this.motivo,
    required this.status,
    this.titulo,
    this.mensagem,
    this.actionKey,
    this.tipoAcao,
    this.mensagemSugerida,
    this.stickyLabel,
    this.stickyLabelCompact,
    this.wearableRelevant,
  });

  static const empty = IaCopilotProximaAcao(
    acao: '',
    motivo: '',
    status: 'ABERTO',
  );

  final String acao;
  final String motivo;
  final String status;
  final String? titulo;
  final String? mensagem;
  final String? actionKey;
  final String? tipoAcao;
  final String? mensagemSugerida;
  final String? stickyLabel;
  final String? stickyLabelCompact;
  final bool? wearableRelevant;

  factory IaCopilotProximaAcao.fromJson(Map<String, dynamic> json) =>
      IaCopilotProximaAcao(
        acao: json['acao'] as String? ?? '',
        motivo: json['motivo'] as String? ?? '',
        status: json['status'] as String? ?? 'ABERTO',
        titulo: json['titulo'] as String?,
        mensagem: json['mensagem'] as String?,
        actionKey: json['actionKey'] as String?,
        tipoAcao: json['tipoAcao'] as String?,
        mensagemSugerida: json['mensagemSugerida'] as String?,
        stickyLabel: json['stickyLabel'] as String?,
        stickyLabelCompact: json['stickyLabelCompact'] as String?,
        wearableRelevant: json['wearableRelevant'] as bool?,
      );

  Map<String, dynamic> toJson() => {
    'acao': acao,
    'motivo': motivo,
    'status': status,
    if (titulo != null) 'titulo': titulo,
    if (mensagem != null) 'mensagem': mensagem,
    if (actionKey != null) 'actionKey': actionKey,
    if (tipoAcao != null) 'tipoAcao': tipoAcao,
    if (mensagemSugerida != null) 'mensagemSugerida': mensagemSugerida,
    if (stickyLabel != null) 'stickyLabel': stickyLabel,
    if (stickyLabelCompact != null) 'stickyLabelCompact': stickyLabelCompact,
    if (wearableRelevant != null) 'wearableRelevant': wearableRelevant,
  };

  String get displayText {
    if (acao.trim().isNotEmpty) return acao.trim();
    final alt = titulo?.trim() ?? mensagem?.trim();
    return (alt == null || alt.isEmpty) ? 'Sem detalhe' : alt;
  }

  String get statusLabel => status.trim().isEmpty ? 'ABERTO' : status.trim();

  bool get hasPersistedActionKey => (actionKey ?? '').trim().isNotEmpty;

  String get rawAcaoOrFallback =>
      acao.isNotEmpty
          ? acao
          : (mensagem ?? titulo ?? '').trim();
}
