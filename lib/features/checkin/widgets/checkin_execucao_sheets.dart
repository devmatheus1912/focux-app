import 'package:flutter/material.dart';

import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../data/checkin_repository.dart';
import '../utils/checkin_execucao_display.dart';

/// Finalizar com exercício faltando pede confirmação; `true` finaliza.
Future<bool> showCheckinFinalizarIncompleto(
  BuildContext context, {
  required int faltam,
}) {
  final s = S.of(context);
  return showFxConfirmSheet(
    context,
    title: s.checkinFaltamExercicios(faltam),
    message: s.checkinFaltamTexto,
    confirmLabel: s.checkinFinalizar,
    cancelLabel: s.checkinVoltarAoTreino,
    icon: Icons.flag_rounded,
  );
}

/// Sessão aberta em outro treino; `true` descarta e inicia este.
Future<bool> showCheckinDescartarAberto(BuildContext context) {
  final s = S.of(context);
  return showFxConfirmSheet(
    context,
    title: s.checkinDescartarAbertoTitulo,
    message: s.checkinDescartarAbertoTexto,
    confirmLabel: s.checkinDescartarEIniciar,
    icon: Icons.delete_outline_rounded,
    destructive: true,
  );
}

/// Segundo toque do "Descartar" do sheet de saída; `true` apaga a sessão.
Future<bool> showCheckinDescartarTreino(BuildContext context) {
  final s = S.of(context);
  return showFxConfirmSheet(
    context,
    title: s.checkinDescartarTreinoTitulo,
    message: s.checkinDescartarTreinoTexto,
    confirmLabel: s.checkinDescartar,
    cancelLabel: s.checkinVoltarAoTreino,
    icon: Icons.delete_outline_rounded,
    destructive: true,
  );
}

String checkinEvolucaoValorLabel(double value, String unidade) {
  final base = checkinKgLabel(value);
  if (unidade.isEmpty) return base;
  return '$base $unidade';
}

Future<int?> showCheckinFilaSheet(
  BuildContext context, {
  required List<ExecucaoExercicio> exercicios,
  int? selectedId,
}) {
  final s = S.of(context);
  return showFxInsetPickerSheet<int>(
    context,
    title: s.checkinFilaTitulo,
    subtitle: s.checkinFilaSub(exercicios.length),
    headerIcon: Icons.format_list_numbered_rounded,
    selected: selectedId,
    items: [
      for (final item in exercicios)
        FxInsetPickerSheetItem(
          value: item.treinoExercicioId,
          label: item.exercicioNome,
          subtitle:
              item.concluido
                  ? s.checkinFilaConcluido
                  : s.checkinFilaSeries(item.seriesFeitas, item.series ?? 0),
          icon:
              item.concluido
                  ? Icons.check_circle_outline_rounded
                  : Icons.fitness_center_rounded,
        ),
    ],
  );
}

/// "Carga em Supino: 20 kg → 22,5 kg (+13%)".
String checkinEvolucaoLinha(S s, EvolucaoPerformance e) {
  final tipo = checkinEvolucaoTipoLabel(s, e.tipo);
  final antes = checkinEvolucaoValorLabel(e.valorAnterior, e.unidade);
  final depois = checkinEvolucaoValorLabel(e.valorAtual, e.unidade);
  final pct = e.percentual;
  return pct == null
      ? s.checkinEvolucaoLinha(tipo, e.exercicioNome, antes, depois)
      : s.checkinEvolucaoLinhaPct(tipo, e.exercicioNome, antes, depois, pct);
}
