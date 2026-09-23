import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../checkin/data/checkin_repository.dart';
import '../../checkin/utils/treino_ficha_status.dart';
import '../utils/aluno_consistencia_display.dart';
import '../utils/aluno_volume_format.dart';

class ProgressoSemanalWidget extends StatelessWidget {
  const ProgressoSemanalWidget({
    super.key,
    required this.treinos,
    required this.historico,
    this.aderenciaPercent,
    this.volumeSemanaKg,
    this.insight,
    this.frequenciaDias,
  });

  final List<ExecucaoTreino> treinos;
  final List<ExecucaoTreino> historico;

  /// Aderência 30d do aluno, se o provider trouxer. Quiet — sem score paralelo.
  final int? aderenciaPercent;

  /// Volume da semana (kg), opcional — densifica Treinos/Home.
  final double? volumeSemanaKg;

  /// Uma linha de insight (ritmo), sem KPI numérico.
  final String? insight;

  /// Dias/semana declarados no plano. Sem isso, não inventa meta.
  final int? frequenciaDias;

  static const _weekdayLetters = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    final weeklyGoal = alunoWeeklyDayGoal(frequenciaDias: frequenciaDias);
    final completedThisWeek = countUniqueCompletedDaysThisWeek(historico);
    final caption = alunoConsistenciaCaption(
      completedThisWeek,
      weeklyGoal: weeklyGoal,
    );
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
      glowStrength: 0,
      padding: const EdgeInsets.all(TokensStrip.s3),
      semanticsLabel:
          'Consistência semanal. $caption'
          '${weeklyGoal != null ? ', meta $weeklyGoal' : ''}'
          '${treinos.isNotEmpty ? ', ${treinos.length} no plano' : ''}.'
          '${aderenciaPercent != null ? ' Aderência $aderenciaPercent por cento.' : ''}'
          '${hasInsight ? ' $insightLine.' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consistência',
            style: FocuxHubTypography.sectionTitle(
              context,
              color: chrome.ink,
            ),
          ),
          const SizedBox(height: TokensStrip.s1),
          Text(
            hasInsight
                ? insightLine
                : 'Dias com treino concluído · descanso não zera',
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
          const SizedBox(height: TokensStrip.s2),
          Text(
            caption,
            style: FocuxHubTypography.chip(chrome.mute),
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
