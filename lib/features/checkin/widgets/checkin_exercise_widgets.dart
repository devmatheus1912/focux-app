import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/checkin_repository.dart';
import '../widgets/gated_pose_coach_panel.dart';
import 'checkin_media_widgets.dart';
import 'checkin_serie_detail_widgets.dart';

class CheckinSerieCard extends StatelessWidget {
  final ExecucaoExercicio ee;
  final int index;
  final int total;
  final bool dark;
  final Color brand;
  final Color ink;
  final Color mute;
  final Color line;
  final String? feedback;
  final void Function(String) onFeedback;
  final void Function(int) onMarcar;
  final void Function(int, ExecucaoSerie?) onSerieDetalhada;

  const CheckinSerieCard({
    super.key,
    required this.ee,
    required this.index,
    required this.total,
    required this.dark,
    required this.brand,
    required this.ink,
    required this.mute,
    required this.line,
    required this.feedback,
    required this.onFeedback,
    required this.onMarcar,
    required this.onSerieDetalhada,
  });

  @override
  Widget build(BuildContext context) {
    final targetSeries = ee.series ?? 0;
    final progress =
        targetSeries == 0
            ? 0.0
            : (ee.seriesFeitas / targetSeries).clamp(0.0, 1.0);
    final hasMedia = ee.gifUrl?.isNotEmpty == true;
    final hasVideo = ee.videoUrl?.isNotEmpty == true;
    final hasThumbnail = !hasVideo && ee.thumbnailUrl?.isNotEmpty == true;
    final loadText = _formatKg(ee.cargaKg);
    final restText =
        ee.descansoSegundos == null ? null : '${ee.descansoSegundos}s';
    final hasPrevious =
        ee.cargaAnteriorKg != null ||
        ee.seriesFeitasAnterior != null ||
        ee.feedbackAnterior != null ||
        ee.rpeAnterior != null;

    return Container(
      decoration:
          ee.concluido
              ? fxListCardDecoration(
                context,
                accent: EagleTokens.good,
                selected: true,
              )
              : fxListCardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: !ee.concluido,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.fromLTRB(TokensStrip.s4, 8, 16, 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color:
                ee.concluido
                    ? EagleTokens.good.withValues(alpha: 0.12)
                    : brand.withValues(alpha: dark ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            ee.concluido ? Icons.check_rounded : Icons.fitness_center_rounded,
            color: ee.concluido ? EagleTokens.good : brand,
            size: 19,
          ),
        ),
        title: Text(
          ee.exercicioNome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            decoration: ee.concluido ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$index/$total  |  ${ee.series ?? '-'} series x ${ee.repeticoes ?? '-'} reps',
            style: TextStyle(
              color: mute,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasVideo) ...[
                  const SizedBox(height: 4),
                  CheckinExerciseVideoPreview(
                    url: ee.videoUrl!,
                    brand: brand,
                    dark: dark,
                  ),
                  const SizedBox(height: 14),
                ] else if (hasThumbnail) ...[
                  const SizedBox(height: 4),
                  CheckinExerciseThumbnailPreview(
                    url: ee.thumbnailUrl!,
                    videoSource: ee.videoSource,
                    licenseStatus: ee.licenseStatus,
                    brand: brand,
                    dark: dark,
                  ),
                  const SizedBox(height: 14),
                ] else if (hasMedia) ...[
                  const SizedBox(height: 4),
                  CheckinExerciseMediaPreview(
                    url: ee.gifUrl!,
                    brand: brand,
                    dark: dark,
                  ),
                  const SizedBox(height: 14),
                ],
                if (!ee.concluido) ...[
                  GatedPoseCoachPanel(
                    exerciseName: ee.exercicioNome,
                    targetReps: _parseTargetReps(ee.repeticoes),
                    brand: brand,
                    dark: dark,
                    onRepCompleted: () {},
                  ),
                  const SizedBox(height: 12),
                ],
                if (loadText != null || restText != null) ...[
                  CheckinExerciseMetaRow(
                    loadText: loadText,
                    restText: restText,
                    ink: ink,
                    mute: mute,
                    line: line,
                    dark: dark,
                  ),
                  const SizedBox(height: 12),
                ],
                if (ee.observacoes?.trim().isNotEmpty == true) ...[
                  CheckinExerciseNote(
                    text: ee.observacoes!.trim(),
                    mute: mute,
                    line: line,
                    dark: dark,
                  ),
                  const SizedBox(height: 12),
                ],
                if (ee.errosComuns?.trim().isNotEmpty == true) ...[
                  CheckinExecutionGuidanceCard(
                    icon: Icons.report_problem_outlined,
                    title: 'Erros comuns',
                    text: ee.errosComuns!.trim(),
                    color: EagleTokens.warn,
                    ink: ink,
                    line: line,
                    dark: dark,
                  ),
                  const SizedBox(height: 12),
                ],
                if (ee.contraindicacoes?.trim().isNotEmpty == true) ...[
                  CheckinExecutionGuidanceCard(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Contraindicacoes',
                    text: ee.contraindicacoes!.trim(),
                    color: EagleTokens.bad,
                    ink: ink,
                    line: line,
                    dark: dark,
                  ),
                  const SizedBox(height: 12),
                ],
                if (ee.substitutos?.trim().isNotEmpty == true) ...[
                  CheckinExecutionGuidanceCard(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Substitutos',
                    text: ee.substitutos!.trim(),
                    color: brand,
                    ink: ink,
                    line: line,
                    dark: dark,
                  ),
                  const SizedBox(height: 12),
                ],
                if (hasPrevious) ...[
                  CheckinPreviousPerformance(
                    loadText: _formatKg(ee.cargaAnteriorKg),
                    seriesText:
                        ee.seriesFeitasAnterior == null
                            ? null
                            : '${ee.seriesFeitasAnterior} series',
                    feedbackText: _formatFeedback(
                      ee.feedbackAnterior,
                      ee.rpeAnterior,
                      ee.dorAnterior,
                    ),
                    ink: ink,
                    mute: mute,
                    line: line,
                    dark: dark,
                  ),
                  const SizedBox(height: 12),
                ],
                if (ee.seriesDetalhes.isNotEmpty) ...[
                  CheckinSeriesHistory(
                    series: ee.seriesDetalhes,
                    ink: ink,
                    mute: mute,
                    line: line,
                    dark: dark,
                    formatKg: _formatKg,
                    formatFeedback: _formatFeedback,
                    onEdit: (serie) => onSerieDetalhada(serie.numero, serie),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor:
                              dark
                                  ? EagleTokens.darkLine
                                  : TokensStrip.borderDefault,
                          valueColor: AlwaysStoppedAnimation(
                            ee.concluido ? EagleTokens.good : brand,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${ee.seriesFeitas}/${ee.series ?? '-'}',
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Series feitas',
                      style: TextStyle(
                        color: mute,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: ShellChrome.of(context).cardFill,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_rounded, size: 18),
                            onPressed:
                                ee.seriesFeitas > 0
                                    ? () => onMarcar(ee.seriesFeitas - 1)
                                    : null,
                          ),
                          SizedBox(
                            width: 30,
                            child: Text(
                              ee.seriesFeitas.toString(),
                              textAlign: TextAlign.center,
                              style: FocuxHubTypography.metric(
                                color: ink,
                                fontSize: FocuxHubTypography.metricEm,
                                fontWeight: FontWeight.w900,
                              ).copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            onPressed:
                                ee.seriesFeitas < targetSeries ||
                                        targetSeries == 0
                                    ? () => onSerieDetalhada(
                                      ee.seriesFeitas + 1,
                                      null,
                                    )
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        ee.seriesFeitas <= 0
                            ? () => onSerieDetalhada(1, null)
                            : () {
                              final last =
                                  ee.seriesDetalhes
                                      .where(
                                        (serie) =>
                                            serie.numero == ee.seriesFeitas,
                                      )
                                      .cast<ExecucaoSerie?>()
                                      .firstOrNull;
                              onSerieDetalhada(ee.seriesFeitas, last);
                            },
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: Text(
                      ee.seriesFeitas <= 0
                          ? 'Registrar serie detalhada'
                          : 'Editar ultima serie',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brand,
                      side: BorderSide(color: brand.withValues(alpha: 0.45)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Como foi?',
                  style: TextStyle(
                    color: mute,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CheckinFeedbackChip(
                      label: 'Facil',
                      selected: feedback == 'FACIL',
                      color: brand,
                      onTap: () => onFeedback('FACIL'),
                    ),
                    CheckinFeedbackChip(
                      label: 'Ok',
                      selected: feedback == 'OK',
                      color: brand,
                      onTap: () => onFeedback('OK'),
                    ),
                    CheckinFeedbackChip(
                      label: 'Dificil',
                      selected: feedback == 'DIFICIL',
                      color: brand,
                      onTap: () => onFeedback('DIFICIL'),
                    ),
                    CheckinFeedbackChip(
                      label: 'Dor',
                      selected: feedback == 'DOR',
                      color: EagleTokens.bad,
                      onTap: () => onFeedback('DOR'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int? _parseTargetReps(String? reps) {
    if (reps == null || reps.trim().isEmpty) return null;
    final match = RegExp(r'\d+').firstMatch(reps);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  String? _formatKg(double? value) {
    if (value == null) return null;
    final rounded =
        value.roundToDouble() == value
            ? value.toStringAsFixed(0)
            : value.toStringAsFixed(1);
    return '$rounded kg';
  }

  String? _formatFeedback(String? feedback, int? rpe, bool? dor) {
    final labels = {
      'FACIL': 'Facil',
      'OK': 'Ok',
      'DIFICIL': 'Dificil',
      'DOR': 'Dor',
    };
    final parts = <String>[
      if (feedback != null) labels[feedback] ?? feedback,
      if (rpe != null) 'RPE $rpe',
      if (dor == true && feedback != 'DOR') 'Dor',
    ];
    return parts.isEmpty ? null : parts.join(' | ');
  }
}

class CheckinExerciseMetaRow extends StatelessWidget {
  final String? loadText;
  final String? restText;
  final Color ink;
  final Color mute;
  final Color line;
  final bool dark;

  const CheckinExerciseMetaRow({
    super.key,
    required this.loadText,
    required this.restText,
    required this.ink,
    required this.mute,
    required this.line,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (loadText != null)
          CheckinTinyMetric(
            icon: Icons.scale_rounded,
            label: 'Carga',
            value: loadText!,
            ink: ink,
            mute: mute,
            line: line,
            dark: dark,
          ),
        if (restText != null)
          CheckinTinyMetric(
            icon: Icons.timer_rounded,
            label: 'Descanso',
            value: restText!,
            ink: ink,
            mute: mute,
            line: line,
            dark: dark,
          ),
      ],
    );
  }
}

class CheckinExerciseNote extends StatelessWidget {
  final String text;
  final Color mute;
  final Color line;
  final bool dark;

  const CheckinExerciseNote({
    super.key,
    required this.text,
    required this.mute,
    required this.line,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: fxListCardDecoration(context),
      child: Text(
        text,
        style: TextStyle(
          color: mute,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class CheckinExecutionGuidanceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  final Color ink;
  final Color line;
  final bool dark;

  const CheckinExecutionGuidanceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
    required this.ink,
    required this.line,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: fxListCardDecoration(context, accent: color),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(
                    color: ink.withValues(alpha: 0.82),
                    fontSize: 12.3,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CheckinPreviousPerformance extends StatelessWidget {
  final String? loadText;
  final String? seriesText;
  final String? feedbackText;
  final Color ink;
  final Color mute;
  final Color line;
  final bool dark;

  const CheckinPreviousPerformance({
    super.key,
    required this.loadText,
    required this.seriesText,
    required this.feedbackText,
    required this.ink,
    required this.mute,
    required this.line,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final details = [
      if (seriesText != null) seriesText!,
      if (loadText != null) loadText!,
      if (feedbackText != null) feedbackText!,
    ].join(' | ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: fxListCardDecoration(
        context,
        accent: Theme.of(context).colorScheme.primary,
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            size: 18,
            color: dark ? Colors.white70 : TokensStrip.textPrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ultima execucao',
                  style: TextStyle(
                    color: mute,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: TextStyle(
                    color: ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CheckinSeriesHistory extends StatelessWidget {
  final List<ExecucaoSerie> series;
  final Color ink;
  final Color mute;
  final Color line;
  final bool dark;
  final String? Function(double?) formatKg;
  final String? Function(String?, int?, bool?) formatFeedback;
  final void Function(ExecucaoSerie) onEdit;

  const CheckinSeriesHistory({
    super.key,
    required this.series,
    required this.ink,
    required this.mute,
    required this.line,
    required this.dark,
    required this.formatKg,
    required this.formatFeedback,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Series registradas',
            style: TextStyle(
              color: mute,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...series.map((serie) {
            final details = [
              if (serie.repeticoes?.isNotEmpty == true) serie.repeticoes!,
              if (formatKg(serie.cargaKg) != null) formatKg(serie.cargaKg)!,
              if (formatFeedback(serie.feedback, serie.rpe, serie.dor) != null)
                formatFeedback(serie.feedback, serie.rpe, serie.dor)!,
            ].join(' | ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: EagleTokens.good.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      serie.numero.toString(),
                      style: const TextStyle(
                        color: EagleTokens.good,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      details.isEmpty ? 'Serie registrada' : details,
                      style: TextStyle(
                        color: ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Editar serie',
                    icon: Icon(Icons.edit_rounded, size: 17, color: mute),
                    onPressed: () => onEdit(serie),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
