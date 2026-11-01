

/// PT-BR labels for financeiro mensalidade status enums.
String financeiroMensalidadeStatusLabel(String status) {
  switch (status.trim().toUpperCase()) {
    case 'PAGO':
      return 'Pago';
    case 'PENDENTE':
      return 'Pendente';
    case 'ATRASADO':
      return 'Atrasado';
    case 'CANCELADO':
      return 'Cancelada';
    default:
      return status;
  }
}

String satelliteFirstName(String? fullName, {String fallback = 'aluno'}) {
  final trimmed = (fullName ?? '').trim();
  if (trimmed.isEmpty) return fallback;
  return trimmed.split(RegExp(r'\s+')).first;
}
