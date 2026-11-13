import 'package:flutter/material.dart';

import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../data/checkin_repository.dart';
import '../utils/checkin_execucao_display.dart';
import '../../../core/theme/fx_icons.dart';

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
    icon: FxIcons.meta,
  );
}

enum CheckinSemSeriesEscolha { jaFiz, descartar }

/// Finalizar sem nenhuma série: a sessão vazia não vira "treino parcial".
/// Ou conta como feito sem registrar (o "Já fiz") ou some.
Future<CheckinSemSeriesEscolha?> showCheckinSemSeries(BuildContext context) {
  final s = S.of(context);
  return showFxInsetPickerSheet<CheckinSemSeriesEscolha>(
    context,
    title: s.checkinSemSeriesTitulo,
    subtitle: s.checkinSemSeriesTexto,
    headerIcon: FxIcons.meta,
    items: [
      FxInsetPickerSheetItem(
        value: CheckinSemSeriesEscolha.jaFiz,
        label: s.checkinSemSeriesJaFiz,
        subtitle: s.checkinSemSeriesJaFizSub,
        icon: FxIcons.concluido,
      ),
      FxInsetPickerSheetItem(
        value: CheckinSemSeriesEscolha.descartar,
        label: s.checkinSemSeriesDescartar,
        subtitle: s.checkinSemSeriesDescartarSub,
        icon: FxIcons.excluir,
      ),
    ],
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
    icon: FxIcons.excluir,
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
    icon: FxIcons.excluir,
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
    headerIcon: FxIcons.listaNumerada,
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
          icon: item.concluido ? FxIcons.concluido : FxIcons.treino,
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
