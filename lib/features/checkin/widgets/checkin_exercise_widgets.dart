import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../data/checkin_repository.dart';
import '../utils/checkin_execucao_display.dart';

class CheckinSerieCard extends StatelessWidget {
  final ExecucaoExercicio ee;
  final int index;
  final int total;
  final VoidCallback onRegistrar;
  final VoidCallback? onDesfazer;
  final VoidCallback? onOpenCoach;
  final VoidCallback? onOpenDemo;
  final VoidCallback? onOpenTips;

  const CheckinSerieCard({
    super.key,
    required this.ee,
    required this.index,
    required this.total,
    required this.onRegistrar,
    this.onDesfazer,
    this.onOpenCoach,
    this.onOpenDemo,
    this.onOpenTips,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final target = ee.series ?? 0;
    final done = ee.concluido || (target > 0 && ee.seriesFeitas >= target);
    final contextLine = checkinSerieContextLine(
      index: index,
      total: total,
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
          Text(
            ee.exercicioNome,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: FocuxHubTypography.sectionTitle(context, color: chrome.ink),
          ),
          const SizedBox(height: TokensStrip.s3),
          Text(
            checkinSerieKpiLabel(ee.seriesFeitas, ee.series),
            textAlign: TextAlign.center,
            style: FocuxHubTypography.kpi(
              color: chrome.ink,
              fontSize: TokensStrip.fontH1,
              fontWeight: FontWeight.w600,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            contextLine,
            textAlign: TextAlign.center,
            style: FocuxTypography.bodySmall(color: chrome.mute),
          ),
          if (previous != null) ...[
            const SizedBox(height: TokensStrip.s2),
            Text(
              previous,
              textAlign: TextAlign.center,
              style: FocuxTypography.bodySmall(color: chrome.mute),
            ),
          ],
          const SizedBox(height: TokensStrip.s5),
          if (!done)
            SizedBox(
              height: checkinExecutionControlMin,
              child: FxLiquidPrimaryButton(
                label: checkinRegistrarLabel(first: ee.seriesFeitas <= 0),
                onPressed: onRegistrar,
              ),
            )
          else
            Text(
              'Exercício concluído',
              textAlign: TextAlign.center,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          if (onDesfazer != null) ...[
            const SizedBox(height: TokensStrip.s2),
            TextButton(
              onPressed: onDesfazer,
              child: Text(checkinDesfazerLabel()),
            ),
          ],
          if (onOpenTips != null || onOpenDemo != null || onOpenCoach != null)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: TokensStrip.s3,
              children: [
                if (onOpenTips != null)
                  TextButton(onPressed: onOpenTips, child: const Text('Dicas')),
                if (onOpenDemo != null)
                  TextButton(
                    onPressed: onOpenDemo,
                    child: const Text('Demonstração'),
                  ),
                if (onOpenCoach != null)
                  TextButton(
                    onPressed: onOpenCoach,
                    child: const Text('Postura'),
                  ),
              ],
            ),
        ],
      ),
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

Future<void> showCheckinExerciseTipsSheet(
  BuildContext context, {
  required ExecucaoExercicio ee,
}) {
  final tips = <FxHelpTip>[
    if (ee.observacoes?.trim().isNotEmpty == true)
      FxHelpTip('Observação', ee.observacoes!.trim(), icon: 'file-text'),
    if (ee.errosComuns?.trim().isNotEmpty == true)
      FxHelpTip('Erros comuns', ee.errosComuns!.trim(), icon: 'alert-triangle'),
    if (ee.contraindicacoes?.trim().isNotEmpty == true)
      FxHelpTip('Contraindicações', ee.contraindicacoes!.trim(), icon: 'heart'),
    if (ee.substitutos?.trim().isNotEmpty == true)
      FxHelpTip('Substitutos', ee.substitutos!.trim(), icon: 'refresh-cw'),
  ];
  if (tips.isEmpty) {
    tips.add(
      const FxHelpTip(
        'Sem dicas',
        'Este exercício não tem observação, erro comum ou substituto cadastrado.',
        icon: 'info',
      ),
    );
  }
  return showFxHelpSheet(
    context,
    title: ee.exercicioNome,
    subtitle: 'Leia e volte — o treino continua na tela.',
    tips: tips,
  );
}

bool checkinExerciseHasTips(ExecucaoExercicio ee) {
  return ee.observacoes?.trim().isNotEmpty == true ||
      ee.errosComuns?.trim().isNotEmpty == true ||
      ee.contraindicacoes?.trim().isNotEmpty == true ||
      ee.substitutos?.trim().isNotEmpty == true;
}

bool checkinExerciseHasDemo(ExecucaoExercicio ee) {
  return ee.gifUrl?.isNotEmpty == true ||
      ee.videoUrl?.isNotEmpty == true ||
      ee.thumbnailUrl?.isNotEmpty == true;
}
