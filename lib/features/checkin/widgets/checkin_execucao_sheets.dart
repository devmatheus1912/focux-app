import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../data/checkin_repository.dart';
import '../utils/checkin_execucao_display.dart';
import 'checkin_media_widgets.dart';
import 'gated_pose_coach_panel.dart';

int? checkinParseTargetReps(String? reps) {
  if (reps == null || reps.trim().isEmpty) return null;
  final match = RegExp(r'\d+').firstMatch(reps);
  return match == null ? null : int.tryParse(match.group(0)!);
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
  return showFxInsetPickerSheet<int>(
    context,
    title: 'Fila do treino',
    subtitle: '${exercicios.length} exercícios',
    headerIcon: Icons.format_list_numbered_rounded,
    selected: selectedId,
    items: [
      for (final item in exercicios)
        FxInsetPickerSheetItem(
          value: item.treinoExercicioId,
          label: item.exercicioNome,
          subtitle:
              item.concluido
                  ? 'Concluído'
                  : '${item.seriesFeitas}/${item.series ?? 0} séries',
          icon:
              item.concluido
                  ? Icons.check_circle_outline_rounded
                  : Icons.fitness_center_rounded,
        ),
    ],
  );
}

Future<void> showCheckinCoachSheet(
  BuildContext context, {
  required ExecucaoExercicio ee,
  bool forAluno = false,
}) {
  final chrome = ShellChrome.of(context);
  final primary = Theme.of(context).colorScheme.primary;
  final brand = chrome.isDark ? BrandPalette.accent(primary) : primary;
  return showFxHomeSheet<void>(
    context,
    builder: (ctx) {
      return FxHomeSheetSurface(
        isDark: chrome.isDark,
        expand: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxHomeSheetHandle(isDark: chrome.isDark),
            FxHomeSheetHeader(
              isDark: chrome.isDark,
              leading: Icon(Icons.accessibility_new_rounded, color: brand),
              title: 'Postura',
              subtitle: ee.exercicioNome,
            ),
            const SizedBox(height: TokensStrip.s3),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  TokensStrip.s4,
                  0,
                  TokensStrip.s4,
                  TokensStrip.s4,
                ),
                child: GatedPoseCoachPanel(
                  exerciseName: ee.exercicioNome,
                  targetReps: checkinParseTargetReps(ee.repeticoes),
                  brand: brand,
                  dark: chrome.isDark,
                  forAluno: forAluno,
                  onRepCompleted: () {},
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showCheckinDemoSheet(
  BuildContext context, {
  required ExecucaoExercicio ee,
}) {
  final chrome = ShellChrome.of(context);
  final primary = Theme.of(context).colorScheme.primary;
  final brand = chrome.isDark ? BrandPalette.accent(primary) : primary;
  return showFxHomeSheet<void>(
    context,
    builder: (ctx) {
      final dark = chrome.isDark;
      Widget preview;
      if (ee.videoUrl?.isNotEmpty == true) {
        preview = CheckinExerciseVideoPreview(
          url: ee.videoUrl!,
          brand: brand,
          dark: dark,
          videoSource: ee.videoSource,
          licenseStatus: ee.licenseStatus,
        );
      } else if (ee.thumbnailUrl?.isNotEmpty == true) {
        preview = CheckinExerciseThumbnailPreview(
          url: ee.thumbnailUrl!,
          videoSource: ee.videoSource,
          licenseStatus: ee.licenseStatus,
          brand: brand,
          dark: dark,
        );
      } else {
        preview = CheckinExerciseMediaPreview(
          url: ee.gifUrl!,
          brand: brand,
          dark: dark,
        );
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s3,
          TokensStrip.s4,
          TokensStrip.s4,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: checkinMediaPreviewHeight),
          child: preview,
        ),
      );
    },
  );
}

Future<void> showCheckinEvolucaoSheet(
  BuildContext context, {
  required List<EvolucaoPerformance> evolucoes,
}) {
  final primary = Theme.of(context).colorScheme.primary;
  return showFxNoticeSheet(
    context,
    title: 'Evolução registrada',
    icon: Icons.trending_up_rounded,
    actionLabel: 'Continuar',
    message:
        'Você evoluiu neste treino. A mensagem também ficou salva no chat com seu personal.',
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
                    '${checkinEvolucaoTipoLabel(evolucao.tipo)} em ${evolucao.exercicioNome}: '
                    '${checkinEvolucaoValorLabel(evolucao.valorAnterior, evolucao.unidade)} → ${checkinEvolucaoValorLabel(evolucao.valorAtual, evolucao.unidade)}'
                    '${evolucao.percentual == null ? '' : ' (+${evolucao.percentual}%)'}',
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
