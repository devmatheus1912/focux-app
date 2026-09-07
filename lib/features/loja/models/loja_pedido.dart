/// Pedido da loja digital — parse na borda API.
class LojaPedido {
  const LojaPedido({
    required this.id,
    required this.buyerEmail,
    required this.valor,
    required this.status,
    this.buyerNome,
    this.pacoteId,
    this.alunoId,
    this.pixCopiaECola,
  });

  final int id;
  final int? pacoteId;
  final int? alunoId;
  final String buyerEmail;
  final String? buyerNome;
  final double valor;
  final String status;
  final String? pixCopiaECola;

  factory LojaPedido.fromJson(Map<String, dynamic> json) => LojaPedido(
    id: (json['id'] as num).toInt(),
    pacoteId: (json['pacoteId'] as num?)?.toInt(),
    alunoId: (json['alunoId'] as num?)?.toInt(),
    buyerEmail: (json['buyerEmail'] ?? '').toString(),
    buyerNome: json['buyerNome']?.toString(),
    valor: LojaPedido.readValor(json['valor']),
    status: (json['status'] ?? '').toString(),
    pixCopiaECola: json['pixCopiaECola']?.toString(),
  );

  static List<LojaPedido> parseList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => LojaPedido.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static double readValor(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }
}

/// Resultado do checkout PIX na loja.
class LojaCheckoutResult {
  const LojaCheckoutResult({
    this.pedidoId,
    this.pixCopiaECola = '',
    this.valor = 0,
  });

  final int? pedidoId;
  final String pixCopiaECola;
  final double valor;

  factory LojaCheckoutResult.fromJson(Map<String, dynamic> json) =>
      LojaCheckoutResult(
        pedidoId: json['pedidoId'] as int?,
        pixCopiaECola: (json['pixCopiaECola'] ?? '').toString(),
        valor: LojaPedido.readValor(json['valor']),
      );
}
