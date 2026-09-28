import 'package:flutter/material.dart';

import '../../../core/widgets/fx_celebration_overlay.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../data/checkin_repository.dart';
import '../utils/checkin_execucao_display.dart';
import '../utils/checkin_execucao_estado.dart';

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

/// Evolução quando houver; senão a celebração de treino concluído.
Future<void> showCheckinResultado(
  BuildContext context, {
  required ExecucaoTreino concluida,
}) {
  final evolucoes = checkinEvolucoesParaCelebrar(concluida);
  if (evolucoes.isNotEmpty) {
    return showCheckinEvolucaoSheet(context, evolucoes: evolucoes);
  }
  final s = S.of(context);
  return FxCelebrationOverlay.show(
    context,
    title: s.checkinConcluidoTitulo,
    subtitle: s.checkinConcluidoTexto,
    icon: Icons.check_circle_rounded,
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

String _evolucaoLinha(S s, EvolucaoPerformance e) {
  final tipo = checkinEvolucaoTipoLabel(s, e.tipo);
  final antes = checkinEvolucaoValorLabel(e.valorAnterior, e.unidade);
  final depois = checkinEvolucaoValorLabel(e.valorAtual, e.unidade);
  final pct = e.percentual;
  return pct == null
      ? s.checkinEvolucaoLinha(tipo, e.exercicioNome, antes, depois)
      : s.checkinEvolucaoLinhaPct(tipo, e.exercicioNome, antes, depois, pct);
}

Future<void> showCheckinEvolucaoSheet(
  BuildContext context, {
  required List<EvolucaoPerformance> evolucoes,
}) {
  final s = S.of(context);
  final primary = Theme.of(context).colorScheme.primary;
  return showFxNoticeSheet(
    context,
    title: s.checkinEvolucaoTitulo,
    icon: Icons.trending_up_rounded,
    actionLabel: s.checkinEvolucaoContinuar,
    message: s.checkinEvolucaoTexto,
    body: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final evolucao in evolucoes.take(4))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.trending_up_rounded, color: primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _evolucaoLinha(s, evolucao),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
