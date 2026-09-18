import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../data/checkin_repository.dart';
import '../utils/checkin_execucao_display.dart';
import '../utils/checkin_exercise_tips.dart';
import 'checkin_media_widgets.dart';

part 'checkin_serie_steppers.part.dart';

class CheckinSerieCard extends StatelessWidget {
  final ExecucaoExercicio ee;
  final int index;
  final int total;
  final VoidCallback onRegistrar;
  final VoidCallback? onDesfazer;
  final VoidCallback? onOpenCoach;
  final VoidCallback? onOpenDemo;
  final VoidCallback? onAjustar;
  final VoidCallback? onConfirmarRestante;
  final VoidCallback? onTrocar;
  final double? draftCargaKg;
  final int? draftReps;
  final VoidCallback? onPlusCarga;
  final VoidCallback? onMinusCarga;
  final VoidCallback? onPlusReps;
  final VoidCallback? onMinusReps;

  const CheckinSerieCard({
    super.key,
    required this.ee,
    required this.index,
    required this.total,
    required this.onRegistrar,
    this.onDesfazer,
    this.onOpenCoach,
    this.onOpenDemo,
    this.onAjustar,
    this.onConfirmarRestante,
    this.onTrocar,
    this.draftCargaKg,
    this.draftReps,
    this.onPlusCarga,
    this.onMinusCarga,
    this.onPlusReps,
    this.onMinusReps,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final brand = chrome.isDark ? BrandPalette.accent(primary) : primary;
    final hasDemo = checkinExerciseHasDemo(ee);
    final target = ee.series ?? 0;
    final done = ee.concluido || (target > 0 && ee.seriesFeitas >= target);
    final contextLine = checkinSerieContextLine(
      seriesReps: checkinSeriesRepsLabel(ee.series, ee.repeticoes),
      carga: checkinCargaLabel(ee.cargaKg),
      descansoSegundos: ee.descansoSegundos,
    );
    final previous = _previousLine(ee);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s2,
        FxSettingsLayout.pageInset,
        TokensStrip.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // S8: um alvo dominante — nome + KPI + receita, agrupados.
          FxStripCard(
            accent: brand,
            glowStrength: 0.08,
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s4,
              TokensStrip.s4,
              TokensStrip.s4,
              TokensStrip.s3,
            ),
            onTap:
                onTrocar == null
                    ? null
                    : () {
                      HapticFeedback.selectionClick();
                      onTrocar!();
                    },
            semanticsLabel:
                onTrocar == null
                    ? null
                    : '${ee.exercicioNome}. ${checkinTrocarExercicioHint(index: index, total: total)}',
            child: Column(
              children: [
                Text(
                  ee.exercicioNome,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.sectionTitle(
                    context,
                    color: chrome.ink,
                  ),
                ),
                if (onTrocar != null) ...[
                  const SizedBox(height: TokensStrip.s1),
                  Text(
                    checkinTrocarExercicioHint(index: index, total: total),
                    textAlign: TextAlign.center,
                    style: FocuxTypography.bodySmall(color: brand),
                  ),
                ],
                const SizedBox(height: TokensStrip.s3),
                Text(
                  checkinSerieKpiLabel(ee.seriesFeitas, ee.series),
                  textAlign: TextAlign.center,
                  style: FocuxHubTypography.kpi(
                    color: brand,
                    fontSize: TokensStrip.fontH1 + 4,
                    fontWeight: FontWeight.w800,
                  ).copyWith(
                    height: 1.05,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: TokensStrip.s2),
                Text(
                  contextLine,
                  textAlign: TextAlign.center,
                  style: FocuxTypography.bodySmall(color: chrome.mute),
                ),
                if (previous != null) ...[
                  const SizedBox(height: TokensStrip.s1),
                  Text(
                    previous,
                    textAlign: TextAlign.center,
                    style: FocuxTypography.bodySmall(color: chrome.mute),
                  ),
                ],
              ],
            ),
          ),
          if (hasDemo) ...[
            const SizedBox(height: TokensStrip.s3),
            FxStripCard(
              emphasize: true,
              glowStrength: 0.14,
              accent: brand,
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
                child: _inlineDemoPreview(
                  ee: ee,
                  brand: brand,
                  dark: chrome.isDark,
                ),
              ),
            ),
          ],
          const SizedBox(height: TokensStrip.s3),
          if (!done) ...[
            FxStripCard(
              accent: brand,
              glowStrength: 0.06,
              padding: const EdgeInsets.symmetric(
                horizontal: TokensStrip.s3,
                vertical: TokensStrip.s3,
              ),
              child: _CheckinSetSteppers(
                cargaKg: draftCargaKg ?? ee.cargaKg,
                reps: draftReps,
                onPlusCarga: onPlusCarga,
                onMinusCarga: onMinusCarga,
                onPlusReps: onPlusReps,
                onMinusReps: onMinusReps,
              ),
            ),
            const SizedBox(height: TokensStrip.s3),
            SizedBox(
              height: checkinExecutionControlMin,
              child: FxLiquidPrimaryButton(
                label: checkinRegistrarLabel(first: ee.seriesFeitas <= 0),
                onPressed: onRegistrar,
              ),
            ),
            if (onAjustar != null ||
                onConfirmarRestante != null ||
                onDesfazer != null ||
                onOpenCoach != null ||
                (onOpenDemo != null && !hasDemo)) ...[
              const SizedBox(height: TokensStrip.s1),
              TextButton(
                onPressed: () async {
                  final items = <FxInsetPickerSheetItem<String>>[
                    if (onAjustar != null)
                      const FxInsetPickerSheetItem(
                        value: 'ajustar',
                        label: 'Ajustar',
                        subtitle: 'Carga, reps e RPE',
                        icon: Icons.tune_rounded,
                      ),
                    if (onConfirmarRestante != null)
                      FxInsetPickerSheetItem(
                        value: 'confirmar',
                        label: checkinConfirmarRestanteLabel(
                          feitas: ee.seriesFeitas,
                          total: ee.series,
                        ),
                        subtitle: 'Marca o que falta de uma vez',
                        icon: Icons.done_all_rounded,
                      ),
                    if (onDesfazer != null)
                      FxInsetPickerSheetItem(
                        value: 'desfazer',
                        label: checkinDesfazerLabel(),
                        subtitle: 'Remove a última série',
                        icon: Icons.undo_rounded,
                      ),
                    if (onOpenCoach != null)
                      const FxInsetPickerSheetItem(
                        value: 'postura',
                        label: 'Postura',
                        subtitle: 'Dicas de execução',
                        icon: Icons.accessibility_new_rounded,
                      ),
                    if (onOpenDemo != null && !hasDemo)
                      const FxInsetPickerSheetItem(
                        value: 'demo',
                        label: 'Demonstração',
                        subtitle: 'Vídeo do exercício',
                        icon: Icons.play_circle_outline_rounded,
                      ),
                  ];
                  if (items.isEmpty) return;
                  final picked = await showFxInsetPickerSheet<String>(
                    context,
                    title: 'Mais na série',
                    subtitle: 'Ajustes e ações secundárias',
                    headerIcon: Icons.more_horiz_rounded,
                    items: items,
                  );
                  switch (picked) {
                    case 'ajustar':
                      onAjustar?.call();
                    case 'confirmar':
                      onConfirmarRestante?.call();
                    case 'desfazer':
                      onDesfazer?.call();
                    case 'postura':
                      onOpenCoach?.call();
                    case 'demo':
                      onOpenDemo?.call();
                  }
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(64, checkinExecutionControlMin),
                ),
                child: Text('Mais', style: TextStyle(color: chrome.mute)),
              ),
            ],
          ] else
            FxStripCard(
              accent: brand,
              glowStrength: 0.04,
              padding: const EdgeInsets.symmetric(
                horizontal: TokensStrip.s4,
                vertical: TokensStrip.s4,
              ),
              child: Text(
                'Exercício concluído',
                textAlign: TextAlign.center,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _inlineDemoPreview({
    required ExecucaoExercicio ee,
    required Color brand,
    required bool dark,
  }) {
    final mediaKey = ValueKey(
      'checkin-demo-${ee.treinoExercicioId}-${ee.videoUrl ?? ee.thumbnailUrl ?? ee.gifUrl}',
    );
    if (ee.videoUrl?.isNotEmpty == true) {
      return CheckinExerciseVideoPreview(
        key: mediaKey,
        url: ee.videoUrl!,
        brand: brand,
        dark: dark,
        videoSource: ee.videoSource,
        licenseStatus: ee.licenseStatus,
      );
    }
    if (ee.thumbnailUrl?.isNotEmpty == true) {
      return CheckinExerciseThumbnailPreview(
        key: mediaKey,
        url: ee.thumbnailUrl!,
        videoSource: ee.videoSource,
        licenseStatus: ee.licenseStatus,
        brand: brand,
        dark: dark,
      );
    }
    return CheckinExerciseMediaPreview(
      key: mediaKey,
      url: ee.gifUrl!,
      brand: brand,
      dark: dark,
    );
  }

  static String? _previousLine(ExecucaoExercicio ee) {
    final parts = <String>[
      if (ee.seriesFeitasAnterior != null) '${ee.seriesFeitasAnterior} séries',
      if (checkinCargaLabel(ee.cargaAnteriorKg) != null)
        checkinCargaLabel(ee.cargaAnteriorKg)!,
    ];
    if (parts.isEmpty) return null;
    return 'Última vez: ${parts.join(' · ')}';
  }
}
