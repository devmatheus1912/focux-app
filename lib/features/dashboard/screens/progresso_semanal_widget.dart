import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../checkin/data/checkin_repository.dart';
import '../../checkin/utils/treino_ficha_status.dart';

class ProgressoSemanalWidget extends StatelessWidget {
  const ProgressoSemanalWidget({
    super.key,
    required this.treinos,
    required this.historico,
  });

  final List<ExecucaoTreino> treinos;
  final List<ExecucaoTreino> historico;

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

    return FxStripCard(
      glowStrength: 0.04,
      padding: const EdgeInsets.all(TokensStrip.s3),
      semanticsLabel:
          'Consistência semanal. $completedThisWeek dias esta semana, '
          'meta $weeklyGoal.',
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
          const SizedBox(height: TokensStrip.s2),
          Text(
            'Treinos concluídos nesta semana · descanso não zera',
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
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
                '$completedThisWeek de $weeklyGoal',
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
