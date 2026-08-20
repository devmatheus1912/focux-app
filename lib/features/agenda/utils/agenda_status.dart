import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../data/agenda_repository.dart';

bool agendaStatusIsActionable(String status) {
  switch (status) {
    case 'AGENDADO':
    case 'CONFIRMADO':
      return true;
    default:
      return false;
  }
}

bool agendaStatusNeedsConfirm(String status) => status == 'AGENDADO';

String agendaStatusLabel(String status) {
  switch (status) {
    case 'AGENDADO':
      return 'Agendado';
    case 'CONFIRMADO':
      return 'Confirmado';
    case 'PRESENTE':
      return 'Presente';
    case 'CONCLUIDO':
      return 'Concluído';
    case 'FALTA':
      return 'Falta';
    case 'CANCELADO':
      return 'Cancelado';
    default:
      return status;
  }
}

Color agendaStatusColor(
  String status, {
  required bool isDark,
  required Color primary,
}) {
  switch (status) {
    case 'CONFIRMADO':
    case 'CONCLUIDO':
    case 'PRESENTE':
      return EagleTokens.semanticGood(isDark: isDark);
    case 'FALTA':
      return EagleTokens.semanticBad(isDark: isDark);
    case 'CANCELADO':
      return isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    default:
      return primary;
  }
}

/// Próximo horário ainda aberto no dia (não passou do fim).
Agendamento? agendaNextOpen(
  List<Agendamento> dayEvents, {
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final open =
      dayEvents
          .where(
            (e) =>
                agendaStatusIsActionable(e.status) && !e.fim.isBefore(n),
          )
          .toList()
        ..sort((a, b) => a.inicio.compareTo(b.inicio));
  return open.isEmpty ? null : open.first;
}

/// Sessão já começou, está para começar ou já passou — o personal fecha o ciclo.
bool agendaSessionIsDue(Agendamento ag, {DateTime? now}) {
  if (!agendaStatusIsActionable(ag.status)) return false;
  final n = now ?? DateTime.now();
  return !ag.inicio.isAfter(n.add(const Duration(minutes: 15)));
}
