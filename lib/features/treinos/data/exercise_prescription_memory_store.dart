import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_prescription_memory.dart';

/// Persiste a última prescrição usada ao adicionar exercício.
class ExercisePrescriptionMemoryStore {
  ExercisePrescriptionMemoryStore._();

  static const _key = 'last_exercise_prescription_v1';

  static Future<void> save(ExercisePrescriptionMemory memory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_toMap(memory)));
  }

  static Future<ExercisePrescriptionMemory?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _fromMap(map);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _toMap(ExercisePrescriptionMemory m) => {
    'presetId': m.presetId,
    'series': m.series,
    'repeticoes': m.repeticoes,
    'descansoSegundos': m.descansoSegundos,
    'tipoSerie': m.tipoSerie,
    'cargaKg': m.cargaKg,
    'observacoes': m.observacoes,
    'grupoSuperset': m.grupoSuperset,
  };

  static ExercisePrescriptionMemory _fromMap(Map<String, dynamic> map) {
    return ExercisePrescriptionMemory(
      presetId: map['presetId'] as String? ?? 'hypertrophy',
      series: map['series'] as int? ?? 3,
      repeticoes: map['repeticoes'] as String? ?? '10-12',
      descansoSegundos: map['descansoSegundos'] as int? ?? 60,
      tipoSerie: map['tipoSerie'] as String? ?? 'NORMAL',
      cargaKg: (map['cargaKg'] as num?)?.toDouble(),
      observacoes: map['observacoes'] as String? ?? '',
      grupoSuperset: map['grupoSuperset'] as int?,
    );
  }
}
