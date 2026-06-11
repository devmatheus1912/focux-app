import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// Accent color for financeiro mensalidade status pills.
Color financeiroMensalidadeStatusColor(String status) {
  switch (status.trim().toUpperCase()) {
    case 'PAGO':
      return EagleTokens.good;
    case 'ATRASADO':
      return EagleTokens.bad;
    default:
      return EagleTokens.warn;
  }
}
