import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../checkin/data/checkin_repository.dart';
import '../../checkin/utils/treino_ficha_status.dart';
import '../utils/aluno_volume_format.dart';

class ProgressoSemanalWidget extends StatelessWidget {
  const ProgressoSemanalWidget({
    super.key,
    required this.treinos,
    required this.historico,
    this.aderenciaPercent,
    this.volumeSemanaKg,
    this.insight,
  });

  final List<ExecucaoTreino> treinos;
  final List<ExecucaoTreino> historico;

  /// Aderência 30d do aluno, se o provider trouxer. Quiet — sem score paralelo.
  final int? aderenciaPercent;

  /// Volume da semana (kg), opcional — densifica Treinos/Home.
  final double? volumeSemanaKg;

  /// Uma linha de insight (ritmo), sem KPI numérico.
  final String? insight;

  static const _weekdayLetters = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    final weeklyGoal = treinos.isEmpty ? 3 : treinos.length.clamp(3, 6);
    final completedThisWeek = countUniqueCompletedDaysThisWeek(historico);
    final progressValue =
        weeklyGoal == 0
            ? 0.0
            : (completedThisWeek / weeklyGoal).clamp(0.0, 1.0);
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final engagementChips = _engagementChips();
    final insightLine = insight?.trim();
    final hasInsight = insightLine != null && insightLine.isNotEmpty;

    return FxStripCard(
      glowStrength: 0.04,
      padding: const EdgeInsets.all(TokensStrip.s3),
      semanticsLabel:
          'Consistência semanal. $completedThisWeek dias esta semana, '
          'meta $weeklyGoal.'
          '${aderenciaPercent != null ? ' Aderência $aderenciaPercent por cento.' : ''}'
          '${hasInsight ? ' $insightLine.' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Consistência',
                  style: FocuxHubTypography.sectionTitle(
                    context,
                    color: chrome.ink,
                  ),
                ),
              ),
              Text(
                completedThisWeek == 1
                    ? '1 dia esta semana'
                    : '$completedThisWeek dias esta semana',
                style: FocuxHubTypography.metric(
                  color: primary,
                  fontSize: FocuxHubTypography.metricMd,
                ),
              ),
            ],
          ),
          if (hasInsight) ...[
            const SizedBox(height: TokensStrip.s1),
            Text(
              insightLine,
              style: FocuxHubTypography.bodyMuted(
                color: chrome.mute,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            const SizedBox(height: TokensStrip.s2),
            Text(
              'Treinos concluídos nesta semana · descanso não zera',
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          ],
          if (engagementChips.isNotEmpty) ...[
            const SizedBox(height: TokensStrip.s2),
            Wrap(
              spacing: TokensStrip.s2,
              runSpacing: TokensStrip.s1,
              children: [
                for (final chip in engagementChips)
                  _QuietMetricChip(
                    label: chip,
                    mute: chrome.mute,
                    ink: chrome.ink,
                  ),
              ],
            ),
          ],
          const SizedBox(height: TokensStrip.s3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final currentDay = DateTime(
                startOfWeek.year,
                startOfWeek.month,
                startOfWeek.day + index,
              );
              final done = _dayHasCompletedWorkout(historico, currentDay);
              final isToday = _isSameCalendarDay(now, currentDay);

              return Container(
                width: TokensStrip.s6,
                height: TokensStrip.s6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      done
                          ? primary.withValues(alpha: 0.18)
                          : (isToday
                              ? primary.withValues(alpha: 0.08)
                              : chrome.line.withValues(alpha: 0.45)),
                  border:
                      isToday
                          ? Border.all(color: primary, width: 1.5)
                          : null,
                ),
                child: Center(
                  child:
                      done
                          ? Icon(Icons.check, color: primary, size: 16)
                          : Text(
                            _weekdayLetters[index],
                            style: FocuxHubTypography.chip(
                              isToday ? primary : chrome.mute,
                            ),
                          ),
                ),
              );
            }),
          ),
          const SizedBox(height: TokensStrip.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: chrome.line.withValues(alpha: 0.55),
                  color: primary,
                  minHeight: TokensStrip.s2,
                  borderRadius: BorderRadius.circular(TokensStrip.rInput),
                ),
              ),
              const SizedBox(width: TokensStrip.s3),
              Text(
                '$completedThisWeek de $weeklyGoal dias',
                style: FocuxHubTypography.metric(
                  color: chrome.ink,
                  fontSize: FocuxHubTypography.metricEm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _engagementChips() {
    final ader = aderenciaPercent;
    final hasAder = ader != null && ader > 0;
    final vol = volumeSemanaKg;
    final hasVol = vol != null && vol > 0;
    // Só monta strip quieto quando há dado de engajamento/volume — sem score.
    if (!hasAder && !hasVol) return const [];
    final chips = <String>[];
    if (hasAder) chips.add('Aderência $ader%');
    if (hasVol) chips.add('Volume ${formatAlunoVolumeKg(vol)}');
    return chips;
  }

  static bool _dayHasCompletedWorkout(
    List<ExecucaoTreino> historico,
    DateTime day,
  ) {
    for (final item in historico) {
      if (normalizeTreinoStatus(item.status) != treinoStatusConcluido) {
        continue;
      }
      final raw = item.concluidoEm ?? item.iniciadoEm;
      if (raw == null) continue;
      final dt = DateTime.tryParse(raw)?.toLocal();
      if (dt == null) continue;
      if (_isSameCalendarDay(dt, day)) return true;
    }
    return false;
  }

  static bool _isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _QuietMetricChip extends StatelessWidget {
  const _QuietMetricChip({
    required this.label,
    required this.mute,
    required this.ink,
  });

  final String label;
  final Color mute;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensStrip.s2,
        vertical: TokensStrip.s1,
      ),
      decoration: BoxDecoration(
        color: mute.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TokensStrip.rPill),
      ),
      child: Text(
        label,
        style: FocuxHubTypography.chip(ink),
      ),
    );
  }
}
