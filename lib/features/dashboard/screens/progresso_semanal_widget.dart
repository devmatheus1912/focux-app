import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressoSemanalWidget extends ConsumerWidget {
  const ProgressoSemanalWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock data for MVP. In reality, this would be fetched from a provider.
    final int streakDays = 5;
    final int weeklyGoal = 4;
    final int completedThisWeek = 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Meu Progresso', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: EagleTokens.warn,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('$streakDays Dias', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Treinos na Semana', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              bool isCompleted = index < completedThisWeek;
              bool isToday = index == completedThisWeek; // simplified logic

              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? EagleTokens.good : (isToday ? Colors.white30 : Colors.white10),
                  border: isToday ? Border.all(color: Colors.white, width: 2) : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.black54, size: 16)
                      : Text(
                          ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'][index],
                          style: TextStyle(color: isToday ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
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
                  value: completedThisWeek / weeklyGoal,
                  backgroundColor: Colors.white24,
                  color: EagleTokens.good,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text('$completedThisWeek/$weeklyGoal', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
