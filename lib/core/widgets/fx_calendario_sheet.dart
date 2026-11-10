import 'package:flutter/material.dart';

import '../theme/fx_icons.dart';
import '../theme/shell_chrome.dart';
import 'fx_home_sheet.dart';
import 'fx_sheet_frame.dart';
import 'fx_tonal_button.dart';

/// Resposta do calendário: `data` nula quando a pessoa escolheu a opção sem
/// data (ex.: "Sem prazo"). Fechar a folha devolve `null` no lugar do record.
typedef FxDataEscolhida = ({DateTime? data});

/// Calendário completo na folha do kit: a única forma de escolher data no app
/// (o diálogo do sistema, `showDatePicker`, é proibido por contrato).
/// Tocar no dia fecha a folha e devolve a data.
Future<FxDataEscolhida?> showFxCalendarioSheet(
  BuildContext context, {
  required String titulo,
  required DateTime primeiro,
  required DateTime ultimo,
  DateTime? inicial,
  String? subtitulo,
  String? semDataLabel,
  DatePickerMode modoInicial = DatePickerMode.day,
}) {
  final inicio = DateUtils.dateOnly(primeiro);
  final fim = DateUtils.dateOnly(ultimo);
  return showFxHomeSheet<FxDataEscolhida>(
    context,
    builder: (ctx) {
      final chrome = ShellChrome.of(ctx);
      return FxSheetFrame(
        title: titulo,
        subtitle: subtitulo,
        leading: Icon(FxIcons.calendario, color: chrome.brand, size: 20),
        footer:
            semDataLabel == null
                ? null
                : FxTonalButton(
                  label: semDataLabel,
                  expanded: true,
                  onPressed:
                      () => FxHomeSheetChrome.dismissAndPop<FxDataEscolhida>(
                        ctx,
                        (data: null),
                      ),
                ),
        child: CalendarDatePicker(
          initialDate: fxCalendarioInicial(inicial, inicio, fim),
          firstDate: inicio,
          lastDate: fim,
          initialCalendarMode: modoInicial,
          onDateChanged:
              (d) => FxHomeSheetChrome.dismissAndPop<FxDataEscolhida>(
                ctx,
                (data: DateUtils.dateOnly(d)),
              ),
        ),
      );
    },
  );
}

/// Dia que o calendário abre: o atual dentro dos limites, senão o limite mais
/// perto (data antiga de uma aula editada, prazo já vencido…).
DateTime fxCalendarioInicial(DateTime? atual, DateTime primeiro, DateTime ultimo) {
  final dia = DateUtils.dateOnly(atual ?? primeiro);
  if (dia.isBefore(primeiro)) return primeiro;
  if (dia.isAfter(ultimo)) return ultimo;
  return dia;
}
