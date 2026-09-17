import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../checkin/data/checkin_repository.dart';
import '../../checkin/utils/treino_ficha_status.dart';

class ProgressoSemanalWidget extends StatelessWidget {
  const ProgressoSemanalWidget({
    super.key,
    required this.treinos,
    required this.historico,
    required this.streakAtual,
  });

  final List<ExecucaoTreino> treinos;
  final List<ExecucaoTreino> historico;
  final int streakAtual;

  static const _weekdayLetters = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final weeklyGoal = treinos.isEmpty ? 3 : treinos.length.clamp(3, 6);
    // Dias com ≥1 CONCLUIDO — não contar N execuções do mesmo dia como N/meta.
    final completedThisWeek = countUniqueCompletedDaysThisWeek(historico);
    final streakDays = streakAtual < 0 ? 0 : streakAtual;
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

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, BrandPalette.deep(cs.primary)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consistência',
                style: FocuxHubTypography.sectionTitle(
                  context,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TokensStrip.s3,
                  vertical: TokensStrip.s1,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(TokensStrip.rPill),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: TokensStrip.fontBodySm + 3,
                    ),
                    const SizedBox(width: TokensStrip.s1),
                    Text(
                      streakDays == 1 ? '1 semana' : '$streakDays semanas',
                      style: FocuxHubTypography.chip(Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s4),
          Text(
            'Treinos concluídos nesta semana',
            style: FocuxHubTypography.bodyMuted(color: Colors.white70),
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            'Semana com pelo menos um treino. Dia de descanso não zera.',
            style: FocuxHubTypography.cardSubtitle(color: Colors.white70),
          ),
          const SizedBox(height: TokensStrip.s2),
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
                          ? Colors.white.withValues(alpha: 0.9)
                          : (isToday ? Colors.white30 : Colors.white10),
                  border:
                      isToday
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                ),
                child: Center(
                  child:
                      done
                          ? Icon(Icons.check, color: cs.primary, size: 16)
                          : Text(
                            _weekdayLetters[index],
                            style: FocuxHubTypography.chip(
                              isToday ? Colors.white : Colors.white54,
                            ),
                          ),
                ),
              );
            }),
          ),
          const SizedBox(height: TokensStrip.s4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                  minHeight: TokensStrip.s2,
                  borderRadius: BorderRadius.circular(TokensStrip.rInput),
                ),
              ),
              const SizedBox(width: TokensStrip.s3),
              Text(
                '$completedThisWeek/$weeklyGoal',
                style: FocuxHubTypography.metric(
                  color: Colors.white,
                  fontSize: FocuxHubTypography.metricEm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Alinha com [countUniqueCompletedDaysThisWeek]: só CONCLUIDO, dia local.
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
