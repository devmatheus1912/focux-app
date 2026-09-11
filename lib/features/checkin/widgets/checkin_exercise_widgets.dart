import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../data/checkin_repository.dart';
import '../utils/checkin_execucao_display.dart';
import 'checkin_media_widgets.dart';

/// Fallback when personal-authored "erros comuns" arrives in English.
const checkinErrosComunsFallback =
    'Peça orientação ao personal se tiver dúvida na execução.';

const _enStopwords = {
  'the',
  'and',
  'with',
  'from',
  'your',
  'you',
  'are',
  'for',
  'that',
  'this',
  'into',
  'keep',
  'avoid',
  'dont',
  "don't",
  'not',
  'too',
  'much',
  'while',
  'during',
  'make',
  'sure',
  'through',
};

const _enExerciseCues = {
  'elbows',
  'elbow',
  'shoulder',
  'shoulders',
  'knees',
  'knee',
  'hips',
  'hip',
  'back',
  'locking',
  'lock',
  'breathe',
  'core',
  'weight',
  'body',
  'down',
  'up',
  'reps',
  'set',
  'sets',
  'form',
  'stance',
  'grip',
};

/// Heuristic: English stopwords / cues vs Portuguese (accents).
bool checkinTextLooksNonPtBr(String text) {
  final raw = text.trim();
  if (raw.isEmpty) return false;
  final lower = raw.toLowerCase();
  final tokens =
      lower
          .split(RegExp(r"[^a-z0-9à-ü']+", caseSensitive: false))
          .where((t) => t.length >= 2)
          .toList();
  if (tokens.isEmpty) return false;

  final enHits = tokens.where(_enStopwords.contains).length;
  final ratio = enHits / tokens.length;
  if (ratio >= 0.18 || enHits >= 3) return true;

  final hasPtAccent = RegExp(
    r'[àáâãäéêíóôõúüç]',
    caseSensitive: false,
  ).hasMatch(raw);
  final hasEnCue = tokens.any(_enExerciseCues.contains);
  final asciiOnly = RegExp(r'^[\x00-\x7F]+$').hasMatch(raw);
  if (asciiOnly && !hasPtAccent && hasEnCue && raw.length > 40) {
    return true;
  }
  return false;
}

String checkinErrosComunsBody(String? errosComuns) {
  final t = errosComuns?.trim() ?? '';
  if (t.isEmpty) return '';
  if (checkinTextLooksNonPtBr(t)) return checkinErrosComunsFallback;
  return t;
}

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
    final primary = Theme.of(context).colorScheme.primary;
    final brand = chrome.isDark ? BrandPalette.accent(primary) : primary;
    final hasDemo = checkinExerciseHasDemo(ee);
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
          if (hasDemo) ...[
            const SizedBox(height: TokensStrip.s3),
            _inlineDemoPreview(ee: ee, brand: brand, dark: chrome.isDark),
            const SizedBox(height: TokensStrip.s4),
          ] else
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
                    child: Text(hasDemo ? 'Ampliar' : 'Demonstração'),
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

  static Widget _inlineDemoPreview({
    required ExecucaoExercicio ee,
    required Color brand,
    required bool dark,
  }) {
    if (ee.videoUrl?.isNotEmpty == true) {
      return CheckinExerciseVideoPreview(
        url: ee.videoUrl!,
        brand: brand,
        dark: dark,
        videoSource: ee.videoSource,
        licenseStatus: ee.licenseStatus,
      );
    }
    if (ee.thumbnailUrl?.isNotEmpty == true) {
      return CheckinExerciseThumbnailPreview(
        url: ee.thumbnailUrl!,
        videoSource: ee.videoSource,
        licenseStatus: ee.licenseStatus,
        brand: brand,
        dark: dark,
      );
    }
    return CheckinExerciseMediaPreview(
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

Future<void> showCheckinExerciseTipsSheet(
  BuildContext context, {
  required ExecucaoExercicio ee,
}) {
  final tips = <FxHelpTip>[
    if (ee.observacoes?.trim().isNotEmpty == true)
      FxHelpTip('Observação', ee.observacoes!.trim(), icon: 'file-text'),
    if (ee.errosComuns?.trim().isNotEmpty == true)
      FxHelpTip(
        'Erros comuns',
        checkinErrosComunsBody(ee.errosComuns),
        icon: 'alert-triangle',
      ),
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
  // Count errosComuns even when EN (sheet shows PT fallback).
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
