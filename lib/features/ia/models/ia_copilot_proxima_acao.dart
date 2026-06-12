/// Próxima ação do Copiloto IA — parse na borda API → modelo imutável.
class IaCopilotProximaAcao {
  const IaCopilotProximaAcao({
    required this.acao,
    required this.motivo,
    required this.status,
    this.titulo,
    this.mensagem,
    this.actionKey,
  });

  final String acao;
  final String motivo;
  final String status;
  final String? titulo;
  final String? mensagem;
  final String? actionKey;

  factory IaCopilotProximaAcao.fromJson(Map<String, dynamic> json) =>
      IaCopilotProximaAcao(
        acao: json['acao'] as String? ?? '',
        motivo: json['motivo'] as String? ?? '',
        status: json['status'] as String? ?? 'ABERTO',
        titulo: json['titulo'] as String?,
        mensagem: json['mensagem'] as String?,
        actionKey: json['actionKey'] as String?,
      );

  String get displayText {
    if (acao.trim().isNotEmpty) return acao.trim();
    final alt = titulo?.trim() ?? mensagem?.trim();
    return (alt == null || alt.isEmpty) ? 'Sem detalhe' : alt;
  }

  String get statusLabel => status.trim().isEmpty ? 'ABERTO' : status.trim();

  bool get hasPersistedActionKey => (actionKey ?? '').trim().isNotEmpty;
}
