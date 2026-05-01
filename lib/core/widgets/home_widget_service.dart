import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to update iOS/Android home screen widget with today's training info.
///
/// Widget shows: workout name, exercise count, completion status.
/// Data is pushed from the app whenever a workout is loaded or completed.
class HomeWidgetService {
  HomeWidgetService._();

  static const _appGroupId = 'group.app.focux.widget';
  static const _iOSWidgetName = 'FocuxTreinoWidget';
  static const _androidWidgetName = 'FocuxTreinoWidget';

  /// Initialize the home widget with app group ID.
  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (e) {
      if (kDebugMode) debugPrint('[HomeWidget] Init error: $e');
    }
  }

  /// Update widget with today's workout data.
  static Future<void> updateTreinoDoDia({
    required String treinoNome,
    required int totalExercicios,
    required int exerciciosConcluidos,
    String? proximoExercicio,
  }) async {
    try {
      await HomeWidget.saveWidgetData('treino_nome', treinoNome);
      await HomeWidget.saveWidgetData('total_exercicios', totalExercicios);
      await HomeWidget.saveWidgetData('concluidos', exerciciosConcluidos);
      await HomeWidget.saveWidgetData('proximo', proximoExercicio ?? '');
      await HomeWidget.saveWidgetData('updated_at', DateTime.now().toIso8601String());

      final pct = totalExercicios > 0 ? (exerciciosConcluidos / totalExercicios * 100).toInt() : 0;
      await HomeWidget.saveWidgetData('progresso_pct', pct);

      await HomeWidget.updateWidget(iOSName: _iOSWidgetName, androidName: _androidWidgetName);

      // Also cache locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_last_treino', jsonEncode({
        'nome': treinoNome,
        'total': totalExercicios,
        'concluidos': exerciciosConcluidos,
        'pct': pct,
      }));
    } catch (e) {
      if (kDebugMode) debugPrint('[HomeWidget] Update error: $e');
    }
  }

  /// Clear widget data (e.g. on logout).
  static Future<void> clear() async {
    try {
      await HomeWidget.saveWidgetData('treino_nome', 'Nenhum treino');
      await HomeWidget.saveWidgetData('total_exercicios', 0);
      await HomeWidget.saveWidgetData('concluidos', 0);
      await HomeWidget.saveWidgetData('proximo', '');
      await HomeWidget.saveWidgetData('progresso_pct', 0);
      await HomeWidget.updateWidget(iOSName: _iOSWidgetName, androidName: _androidWidgetName);
    } catch (e) {
      if (kDebugMode) debugPrint('[HomeWidget] Clear error: $e');
    }
  }

  /// Register callback for widget interactions (e.g. tap to open app).
  static Future<void> registerInteractivity() async {
    try {
      await HomeWidget.registerInteractivityCallback(widgetCallback);
    } catch (e) {
      if (kDebugMode) debugPrint('[HomeWidget] Callback error: $e');
    }
  }

  /// Callback when user interacts with the widget.
  @pragma('vm:entry-point')
  static Future<void> widgetCallback(Uri? uri) async {
    // Widget taps will deep-link into the app via GoRouter
    if (kDebugMode) debugPrint('[HomeWidget] Callback: $uri');
  }
}
