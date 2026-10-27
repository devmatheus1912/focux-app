import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_prescription_memory.dart';
import '../utils/prescricao_padrao_bloco.dart';
import '../utils/prescricao_serie.dart';

/// Persiste a última prescrição usada ao adicionar exercício.
class ExercisePrescriptionMemoryStore {
  ExercisePrescriptionMemoryStore._();

  static const _key = 'last_exercise_prescription_v1';

  static Future<void> saveFor(
    int exercicioId,
    List<SeriePrescrita> series, {
    String bloco = 'TRABALHO',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      chaveMemoriaDoExercicio(exercicioId, bloco),
      jsonEncode([for (final serie in series) serie.toJson()]),
    );
    // Aquecimento e alongamento não viram o "último usado" do trabalho.
    if (series.isEmpty || !usaMemoriaGlobal(bloco)) return;
    final valida = series.firstWhere(
      (serie) => serie.papel != 'AQUECIMENTO',
      orElse: () => series.first,
    );
    await save(
      ExercisePrescriptionMemory(
        presetId: 'hypertrophy',
        series: series.length,
        repeticoes: valida.repeticoes,
        descansoSegundos: prescricaoHipertrofiaDescanso,
        tipoSerie: 'NORMAL',
        cargaKg: valida.cargaKg,
        observacoes: '',
      ),
    );
  }

  static Future<List<SeriePrescrita>?> loadFor(
    int exercicioId, {
    String bloco = 'TRABALHO',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(chaveMemoriaDoExercicio(exercicioId, bloco));
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((item) => SeriePrescrita.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<List<SeriePrescrita>?> loadGlobalSeries() async {
    final memory = await load();
    if (memory == null || memory.series < 1) return null;
    return [
      for (var n = 1; n <= memory.series; n++)
        SeriePrescrita(
          numero: n,
          repeticoes: memory.repeticoes,
          cargaKg: memory.cargaKg,
        ),
    ];
  }

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
