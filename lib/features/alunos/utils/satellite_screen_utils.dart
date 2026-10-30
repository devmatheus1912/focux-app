import 'package:flutter/material.dart';


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

/// Centers a full-width empty panel with scroll + safe padding.
Widget satelliteEmptyBody({required Widget child}) {
  return Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: child,
    ),
  );
}

String satelliteFirstName(String? fullName, {String fallback = 'aluno'}) {
  final trimmed = (fullName ?? '').trim();
  if (trimmed.isEmpty) return fallback;
  return trimmed.split(RegExp(r'\s+')).first;
}
