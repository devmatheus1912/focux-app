enum LojaHubView { vitrine, pedidos }

String lojaHubViewLabel(LojaHubView view) => switch (view) {
  LojaHubView.vitrine => 'Vitrine',
  LojaHubView.pedidos => 'Pedidos',
};

String lojaHubSubtitle({required LojaHubView view, String? freshness}) {
  final label = lojaHubViewLabel(view);
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return label;
  return '$label · $stamp';
}

String lojaPacoteSubtitle({String? descricao, required int duracaoMeses}) {
  final desc = descricao?.trim();
  if (desc != null && desc.isNotEmpty) return desc;
  if (duracaoMeses <= 1) return '1 mês';
  return '$duracaoMeses meses';
}

String lojaPedidoStatusLabel(String status) {
  switch (status.trim().toUpperCase()) {
    case 'PAGO':
    case 'CONFIRMADO':
    case 'PAID':
      return 'Pago';
    case 'PENDENTE':
    case 'PENDING':
      return 'Pendente';
    case 'CANCELADO':
    case 'CANCELLED':
      return 'Cancelado';
    case 'EXPIRADO':
    case 'EXPIRED':
      return 'Expirado';
    case '':
      return 'Sem status';
    default:
      return status.trim();
  }
}

String lojaPedidoLabel({String? buyerNome, required String buyerEmail}) {
  final nome = buyerNome?.trim();
  if (nome != null && nome.isNotEmpty) return nome;
  final email = buyerEmail.trim();
  return email.isEmpty ? 'Comprador' : email;
}

String lojaPedidoSubtitle({
  String? buyerNome,
  required String buyerEmail,
  required String status,
}) {
  final statusLabel = lojaPedidoStatusLabel(status);
  final nome = buyerNome?.trim();
  final email = buyerEmail.trim();
  if (nome != null && nome.isNotEmpty && email.isNotEmpty) {
    return '$statusLabel · $email';
  }
  return statusLabel;
}

bool lojaPedidoPendente(String status) {
  switch (status.trim().toUpperCase()) {
    case 'PENDENTE':
    case 'PENDING':
      return true;
    default:
      return false;
  }
}

String? lojaPedidoPix(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  return value;
}

String lojaPedidoFxIcon(String status) {
  switch (status.trim().toUpperCase()) {
    case 'PAGO':
    case 'CONFIRMADO':
    case 'PAID':
      return 'circle-check';
    case 'CANCELADO':
    case 'CANCELLED':
    case 'EXPIRADO':
    case 'EXPIRED':
      return 'alert-triangle';
    default:
      return 'pix';
  }
}
