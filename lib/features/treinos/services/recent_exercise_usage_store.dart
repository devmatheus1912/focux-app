import 'package:shared_preferences/shared_preferences.dart';

/// Histórico local dos exercícios mais usados pelo personal.
class RecentExerciseUsageStore {
  RecentExerciseUsageStore._();

  static const _key = 'recent_exercise_usage_v1';
  static const _maxItems = 24;

  static Future<void> recordUsage(int exercicioId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final counts = <int, int>{};
    for (final entry in raw) {
      final parts = entry.split(':');
      if (parts.length != 2) continue;
      final id = int.tryParse(parts[0]);
      final count = int.tryParse(parts[1]);
      if (id != null && count != null) counts[id] = count;
    }
    counts[exercicioId] = (counts[exercicioId] ?? 0) + 1;
    final sorted =
        counts.entries.toList()..sort((a, b) {
          final byCount = b.value.compareTo(a.value);
          if (byCount != 0) return byCount;
          return a.key.compareTo(b.key);
        });
    final next = sorted
        .take(_maxItems)
        .map((e) => '${e.key}:${e.value}')
        .toList(growable: false);
    await prefs.setStringList(_key, next);
  }

  static Future<List<int>> recentIds({int limit = 6}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final ids = <int>[];
    for (final entry in raw) {
      final id = int.tryParse(entry.split(':').first);
      if (id != null) ids.add(id);
      if (ids.length >= limit) break;
    }
    return ids;
  }
}
