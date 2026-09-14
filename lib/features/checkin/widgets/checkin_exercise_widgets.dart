import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_strip_card.dart';
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
  final VoidCallback? onAjustar;
  final VoidCallback? onConfirmarRestante;
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
    this.onOpenTips,
    this.onAjustar,
    this.onConfirmarRestante,
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
              color: brand,
              fontSize: TokensStrip.fontH1 + 14,
              fontWeight: FontWeight.w800,
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
            const SizedBox(height: TokensStrip.s4),
          ] else
            const SizedBox(height: TokensStrip.s5),
          if (!done) ...[
            _CheckinSetSteppers(
              cargaKg: draftCargaKg ?? ee.cargaKg,
              reps: draftReps,
              onPlusCarga: onPlusCarga,
              onMinusCarga: onMinusCarga,
              onPlusReps: onPlusReps,
              onMinusReps: onMinusReps,
            ),
            const SizedBox(height: TokensStrip.s3),
            SizedBox(
              height: checkinExecutionControlMin,
              child: FxLiquidPrimaryButton(
                label: checkinRegistrarLabel(first: ee.seriesFeitas <= 0),
                onPressed: onRegistrar,
              ),
            ),
            if (onAjustar != null || onConfirmarRestante != null) ...[
              const SizedBox(height: TokensStrip.s2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onAjustar != null)
                    TextButton(
                      onPressed: onAjustar,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(64, checkinExecutionControlMin),
                      ),
                      child: Text(
                        'Ajustar',
                        style: TextStyle(color: chrome.mute),
                      ),
                    ),
                  if (onConfirmarRestante != null)
                    TextButton(
                      onPressed: onConfirmarRestante,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(64, checkinExecutionControlMin),
                      ),
                      child: Text(
                        'Confirmar restantes',
                        style: TextStyle(color: chrome.mute),
                      ),
                    ),
                ],
              ),
            ],
          ] else
            Text(
              'Exercício concluído',
              textAlign: TextAlign.center,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          if (onDesfazer != null) ...[
            const SizedBox(height: TokensStrip.s2),
            TextButton(
              onPressed: onDesfazer,
              child: Text(
                checkinDesfazerLabel(),
                style: TextStyle(color: chrome.mute),
              ),
            ),
          ],
          if (onOpenCoach != null ||
              (onOpenDemo != null && !hasDemo) ||
              onOpenTips != null) ...[
            const SizedBox(height: TokensStrip.s3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onOpenCoach != null)
                  _CheckinPosturaHelp(onTap: onOpenCoach!, ink: chrome.ink),
                if (onOpenDemo != null && !hasDemo)
                  TextButton(
                    onPressed: onOpenDemo,
                    child: const Text('Demonstração'),
                  ),
                // Dicas ficam no ? do header (S8 chrome mínimo).
                if (onOpenTips != null && onOpenCoach == null)
                  TextButton(onPressed: onOpenTips, child: const Text('Dicas')),
              ],
            ),
          ],
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

class _CheckinSetSteppers extends StatelessWidget {
  const _CheckinSetSteppers({
    required this.cargaKg,
    required this.reps,
    this.onPlusCarga,
    this.onMinusCarga,
    this.onPlusReps,
    this.onMinusReps,
  });

  final double? cargaKg;
  final int? reps;
  final VoidCallback? onPlusCarga;
  final VoidCallback? onMinusCarga;
  final VoidCallback? onPlusReps;
  final VoidCallback? onMinusReps;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Row(
      children: [
        Expanded(
          child: _CheckinStepper(
            label: 'kg',
            value: checkinCargaLabel(cargaKg) ?? '—',
            onMinus: onMinusCarga,
            onPlus: onPlusCarga,
            mute: chrome.mute,
            ink: chrome.ink,
          ),
        ),
        const SizedBox(width: TokensStrip.s3),
        Expanded(
          child: _CheckinStepper(
            label: 'reps',
            value: reps == null ? '—' : '$reps',
            onMinus: onMinusReps,
            onPlus: onPlusReps,
            mute: chrome.mute,
            ink: chrome.ink,
          ),
        ),
      ],
    );
  }
}

class _CheckinStepper extends StatelessWidget {
  const _CheckinStepper({
    required this.label,
    required this.value,
    required this.mute,
    required this.ink,
    this.onMinus,
    this.onPlus,
  });

  final String label;
  final String value;
  final Color mute;
  final Color ink;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: FocuxHubTypography.bodyMuted(color: mute)),
        const SizedBox(height: TokensStrip.s1),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onMinus,
              tooltip: 'Diminuir $label',
              style: IconButton.styleFrom(
                minimumSize: const Size(
                  checkinExecutionControlMin,
                  checkinExecutionControlMin,
                ),
              ),
              icon: Icon(Icons.remove_rounded, color: ink),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: FocuxHubTypography.sectionTitle(context, color: ink),
              ),
            ),
            IconButton(
              onPressed: onPlus,
              tooltip: 'Aumentar $label',
              style: IconButton.styleFrom(
                minimumSize: const Size(
                  checkinExecutionControlMin,
                  checkinExecutionControlMin,
                ),
              ),
              icon: Icon(Icons.add_rounded, color: ink),
            ),
          ],
        ),
      ],
    );
  }
}

/// Postura: rótulo + `FxHelpIconButton` canônico (não outlined genérico).
class _CheckinPosturaHelp extends StatelessWidget {
  const _CheckinPosturaHelp({required this.onTap, required this.ink});

  final VoidCallback onTap;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensStrip.s2,
        vertical: TokensStrip.s1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Postura',
            style: FocuxHubTypography.bodyMuted(
              color: ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: FxHelpChrome.gap),
          FxHelpIconButton(
            tooltip: 'Ajuda de postura',
            onTap: onTap,
            expandHitTarget: true,
          ),
        ],
      ),
    );
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
