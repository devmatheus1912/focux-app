import 'package:flutter/material.dart';

/// Escolha de horário do app: o relógio do sistema, em 24 h, com "Cancelar" e
/// "OK" e o tema do app. O calendário usa a folha do kit; o horário usa o
/// relógio que o usuário já conhece. `showTimePicker` só existe aqui (contrato).
Future<TimeOfDay?> showFxHorario(
  BuildContext context, {
  required String titulo,
  required TimeOfDay inicial,
}) {
  return showTimePicker(
    context: context,
    initialTime: inicial,
    helpText: titulo,
    cancelText: 'Cancelar',
    confirmText: 'OK',
    builder:
        (ctx, child) => MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
  );
}
