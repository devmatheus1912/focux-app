import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_number_pad_sheet.dart';
import '../../../core/widgets/fx_set_dots.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';
import '../data/checkin_repository.dart';
import '../utils/checkin_execucao_display.dart';
import '../utils/checkin_execucao_estado.dart';
import '../utils/checkin_exercise_tips.dart';
import 'checkin_media_widgets.dart';

part 'checkin_serie_steppers.part.dart';

/// Exercício atual em três zonas, sem rolagem no caso comum:
/// topo fixo (nome, bolinhas), mídia compacta no meio e, na base, carga e reps.
/// Só a mídia cede espaço; sem altura (tela baixa, letra grande) vira rolagem e
/// o vídeo passa a ser o botão "Ver vídeo".
/// Registrar a série fica no rodapé fixo da tela (zona do polegar).
class CheckinSerieCard extends StatelessWidget {
  final ExecucaoExercicio ee;
  final int index;
  final int total;
  final VoidCallback? onTrocar;
  final double? draftCargaKg;
  final int? draftReps;
  final VoidCallback? onPlusCarga;
  final VoidCallback? onMinusCarga;
  final VoidCallback? onPlusReps;
  final VoidCallback? onMinusReps;

  /// Toque no número: digitar o valor em vez de somar de 2,5 em 2,5.
  final ValueChanged<double>? onEditarCarga;
  final ValueChanged<int>? onEditarReps;
  final String? concluidoFrase;

  const CheckinSerieCard({
    super.key,
    required this.ee,
    required this.index,
    required this.total,
    this.onTrocar,
    this.draftCargaKg,
    this.draftReps,
    this.onPlusCarga,
    this.onMinusCarga,
    this.onPlusReps,
    this.onMinusReps,
    this.onEditarCarga,
    this.onEditarReps,
    this.concluidoFrase,
  });

  /// Abaixo disso (dp) não cabem topo, mídia e base juntos.
  static const double alturaMinimaTresZonas = 520;

  /// Mídia menor que isso vira o botão "Ver vídeo".
  static const double alturaMinimaMidia = 96;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final brand = chrome.isDark ? BrandPalette.accent(primary) : primary;
    final hasDemo = checkinExerciseHasDemo(ee);
    final done = !checkinPodeRegistrar(ee);

    final topo = _topo(context, brand: brand);
    final base =
        done
            ? FxStripCard(
              accent: brand,
              glowStrength: 0.04,
              padding: const EdgeInsets.all(TokensStrip.s4),
              child: Text(
                concluidoFrase ?? s.checkinExercicioConcluido,
                textAlign: TextAlign.center,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            )
            : FxStripCard(
              accent: brand,
              glowStrength: 0,
              padding: const EdgeInsets.all(TokensStrip.s3),
              child: _CheckinSetSteppers(
                cargaKg: draftCargaKg ?? ee.proximaCargaKg ?? ee.cargaKg,
                reps: draftReps,
                onPlusCarga: onPlusCarga,
                onMinusCarga: onMinusCarga,
                onPlusReps: onPlusReps,
                onMinusReps: onMinusReps,
                onEditarCarga: onEditarCarga,
                onEditarReps: onEditarReps,
                cargaAnteriorKg: ee.cargaAnteriorKg,
              ),
            );

    const pad = EdgeInsets.fromLTRB(
      FxSettingsLayout.pageInset,
      TokensStrip.s2,
      FxSettingsLayout.pageInset,
      TokensStrip.s3,
    );

    return LayoutBuilder(
      builder: (context, c) {
        final escala = MediaQuery.textScalerOf(context).scale(1);
        final apertado =
            c.maxHeight < alturaMinimaTresZonas || escala > 1.5;
        if (apertado) {
          return SingleChildScrollView(
            padding: pad,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                topo,
                if (hasDemo) ...[
                  const SizedBox(height: TokensStrip.s2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _botaoVerVideo(context),
                  ),
                ],
                const SizedBox(height: TokensStrip.s3),
                base,
              ],
            ),
          );
        }
        return Padding(
          padding: pad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              topo,
              const SizedBox(height: TokensStrip.s3),
              Expanded(
                child:
                    hasDemo
                        ? _midia(context, brand: brand, dark: chrome.isDark)
                        : const SizedBox.shrink(),
              ),
              const SizedBox(height: TokensStrip.s3),
              base,
            ],
          ),
        );
      },
    );
  }

  Widget _botaoVerVideo(BuildContext context) {
    return FxTonalButton(
      label: S.of(context).checkinVerVideo,
      icon: Icons.play_circle_outline_rounded,
      compact: true,
      onPressed: () => _abrirVideoEmFolha(context),
    );
  }

  /// Vídeo em folha, na altura natural dele, para quando não cabe no meio.
  void _abrirVideoEmFolha(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final brand = chrome.isDark ? BrandPalette.accent(primary) : primary;
    showFxHomeSheet<void>(
      context,
      builder:
          (ctx) => FxHomeSheetSurface(
            isDark: chrome.isDark,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FxHomeSheetHandle(isDark: chrome.isDark),
                const SizedBox(height: TokensStrip.s3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(TokensStrip.rCard),
                  child: _inlineDemoPreview(
                    ee: ee,
                    brand: brand,
                    dark: chrome.isDark,
                  ),
                ),
                const SizedBox(height: TokensStrip.s3),
              ],
            ),
          ),
    );
  }

  /// Mídia no meio: ocupa o que sobrou (no máximo a altura natural) e, se sobrar
  /// pouco, vira o botão "Ver vídeo".
  Widget _midia(
    BuildContext context, {
    required Color brand,
    required bool dark,
  }) {
    return LayoutBuilder(
      builder: (context, m) {
        if (m.maxHeight < alturaMinimaMidia) {
          return Center(child: _botaoVerVideo(context));
        }
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: m.maxHeight),
            child: FxStripCard(
              glowStrength: 0.04,
              accent: brand,
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
                child: _inlineDemoPreview(ee: ee, brand: brand, dark: dark),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Topo fixo: nome, trocar, série atual e bolinhas.
  Widget _topo(BuildContext context, {required Color brand}) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final contextLine = checkinSerieContextLine(
      s,
      seriesReps: checkinSeriesRepsLabel(ee.series, ee.repeticoes),
      carga: checkinCargaLabel(ee.proximaCargaKg ?? ee.cargaKg),
      descansoSegundos: ee.descansoSegundos,
    );
    final previous = _previousLine(s, ee);
    final trocarHint = checkinTrocarExercicioHint(
      s,
      index: index,
      total: total,
    );
    final dots = _dots(ee);
    final kpi =
        ee.proximaSeriePapel == 'AQUECIMENTO'
            ? 'Aquecimento · ${checkinSerieKpiLabel(ee.seriesFeitas, ee.series)}'
            : checkinSerieKpiLabel(ee.seriesFeitas, ee.series);

    return FxStripCard(
      accent: brand,
      glowStrength: 0.04,
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        TokensStrip.s3,
        TokensStrip.s3,
        TokensStrip.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: TokensStrip.s1),
                  child: Text(
                    ee.exercicioNome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.pageTitle(
                      context,
                      color: chrome.ink,
                    ),
                  ),
                ),
              ),
              if (onTrocar != null) ...[
                const SizedBox(width: TokensStrip.s2),
                IconButton(
                  tooltip: trocarHint,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onTrocar!();
                  },
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    side: BorderSide(color: brand.withValues(alpha: 0.35)),
                    backgroundColor: brand.withValues(alpha: 0.08),
                  ),
                  icon: Icon(Icons.swap_horiz_rounded, color: brand),
                ),
              ],
            ],
          ),
          const SizedBox(height: TokensStrip.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                kpi,
                style: FocuxHubTypography.metric(
                  color: brand,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ).copyWith(
                  height: 1.05,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (dots.isNotEmpty) ...[
                const SizedBox(width: TokensStrip.s3),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FxSetDots(series: dots, accent: brand),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            contextLine,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
          if (previous != null)
            Text(
              previous,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
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

  /// Uma bolinha por série prescrita; as feitas mostram "40×10".
  static List<FxSetDot> _dots(ExecucaoExercicio ee) {
    final total = ee.series ?? 0;
    if (total < 1 || total > 10) return const [];
    ExecucaoSerie? feita(int n) {
      for (final d in ee.seriesDetalhes) {
        if (d.numero == n) return d;
      }
      return null;
    }

    return [
      for (var n = 1; n <= total; n++)
        FxSetDot(
          numero: n,
          feita: n <= ee.seriesFeitas,
          detalhe: n <= ee.seriesFeitas ? _detalhe(feita(n)) : null,
        ),
    ];
  }

  static String? _detalhe(ExecucaoSerie? d) {
    if (d == null) return null;
    final carga = d.cargaKg == null ? null : checkinCargaLabel(d.cargaKg);
    final cargaCurta = carga?.replaceAll(' kg', '');
    final reps = d.repeticoes?.trim();
    final temReps = reps != null && reps.isNotEmpty;
    if (cargaCurta != null && temReps) return '$cargaCurta×$reps';
    return cargaCurta ?? (temReps ? '$reps reps' : null);
  }

  static String? _previousLine(S s, ExecucaoExercicio ee) {
    final parts = <String>[
      if (ee.seriesFeitasAnterior != null)
        s.checkinNSeries(ee.seriesFeitasAnterior!),
      if (checkinCargaLabel(ee.cargaAnteriorKg) != null)
        checkinCargaLabel(ee.cargaAnteriorKg)!,
    ];
    if (parts.isEmpty) return null;
    return s.checkinUltimaVez(parts.join(' · '));
  }
}
