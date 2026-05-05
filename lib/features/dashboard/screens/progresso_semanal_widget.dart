import 'package:flutter/material.dart';
import '../../../core/theme/brand_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../checkin/providers/checkin_provider.dart';

class ProgressoSemanalWidget extends ConsumerWidget {
  const ProgressoSemanalWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinosAsync = ref.watch(meusTreinosProvider);
    final historicoAsync = ref.watch(historicoCheckinProvider);
    final cs = Theme.of(context).colorScheme;

    return treinosAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (treinos) {
        final historico = historicoAsync.valueOrNull ?? const [];
        final weeklyGoal = treinos.isEmpty ? 3 : treinos.length.clamp(3, 6);
        final completedThisWeek =
            historico.where((t) => _isSameWeek(t.concluidoEm)).length;
        final streakDays = _calculateStreak(historico);
        final progressValue =
            weeklyGoal == 0
                ? 0.0
                : (completedThisWeek / weeklyGoal).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, BrandPalette.deep(cs.primary)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Consistência',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$streakDays dias',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Treinos concluídos nesta semana',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final now = DateTime.now();
                  final startOfWeek = now.subtract(
                    Duration(days: now.weekday - 1),
                  );
                  final currentDay = DateTime(
                    startOfWeek.year,
                    startOfWeek.month,
                    startOfWeek.day + index,
                  );
                  final done = historico.any(
                    (t) => _sameDate(t.concluidoEm, currentDay),
                  );
                  final isToday = _sameDateIso(
                    DateTime.now().toIso8601String(),
                    currentDay,
                  );

                  return Container(
                    width: 32,
                    height: 32,
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
                                ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'][index],
                                style: TextStyle(
                                  color:
                                      isToday ? Colors.white : Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$completedThisWeek/$weeklyGoal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isSameWeek(String? iso) {
    if (iso == null) return false;
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return false;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final normalizedWeek = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final endOfWeek = normalizedWeek.add(const Duration(days: 7));
    return dt.isAfter(normalizedWeek.subtract(const Duration(seconds: 1))) &&
        dt.isBefore(endOfWeek);
  }

  int _calculateStreak(List<dynamic> historico) {
    final dates =
        historico
            .map((t) => DateTime.tryParse(t.concluidoEm ?? '')?.toLocal())
            .whereType<DateTime>()
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    if (dates.isEmpty) return 0;

    var streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    for (final date in dates) {
      if (date == cursor) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (date == cursor.subtract(const Duration(days: 1)) &&
          streak == 0) {
        streak++;
        cursor = date.subtract(const Duration(days: 1));
      }
    }
    return streak;
  }

  bool _sameDate(String? iso, DateTime day) {
    if (iso == null) return false;
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return false;
    return dt.year == day.year && dt.month == day.month && dt.day == day.day;
  }

  bool _sameDateIso(String iso, DateTime day) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return false;
    return dt.year == day.year && dt.month == day.month && dt.day == day.day;
  }
}
