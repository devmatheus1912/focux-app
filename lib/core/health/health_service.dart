import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integrates with Apple Health (iOS) and Google Fit (Android).
///
/// Syncs: steps, heart rate, calories burned, sleep, workouts.
/// Data is cached locally and optionally sent to the backend.
class HealthService {
  HealthService._();

  static final Health _health = Health();
  static const _prefKey = 'health_authorized';

  static final _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WORKOUT,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
  ];

  static final _permissions = _types.map((_) => HealthDataAccess.READ).toList();

  /// Request authorization to read health data.
  /// Returns true if access was granted.
  static Future<bool> requestAuthorization() async {
    try {
      final granted = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, granted);
      return granted;
    } catch (e) {
      if (kDebugMode) debugPrint('[HealthService] Auth error: $e');
      return false;
    }
  }

  /// Check if we already have authorization.
  static Future<bool> isAuthorized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  /// Fetch steps for today.
  static Future<int> getTodaySteps() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps ?? 0;
    } catch (e) {
      if (kDebugMode) debugPrint('[HealthService] Steps error: $e');
      return 0;
    }
  }

  /// Fetch health data for a given period.
  static Future<List<HealthDataPoint>> getHealthData({
    required DateTime start,
    required DateTime end,
    List<HealthDataType>? types,
  }) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: types ?? _types,
        startTime: start,
        endTime: end,
      );
      return _health.removeDuplicates(data);
    } catch (e) {
      if (kDebugMode) debugPrint('[HealthService] Fetch error: $e');
      return [];
    }
  }

  /// Get today's summary: steps, calories, heart rate, sleep hours.
  static Future<HealthSummary> getTodaySummary() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    final data = await getHealthData(start: midnight, end: now);
    final steps = await getTodaySteps();

    double calories = 0;
    double avgHeartRate = 0;
    int hrCount = 0;
    double sleepMinutes = 0;

    for (final point in data) {
      final value = (point.value as NumericHealthValue).numericValue;
      switch (point.type) {
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          calories += value.toDouble();
          break;
        case HealthDataType.HEART_RATE:
          avgHeartRate += value.toDouble();
          hrCount++;
          break;
        case HealthDataType.SLEEP_ASLEEP:
          sleepMinutes += value.toDouble();
          break;
        default:
          break;
      }
    }

    return HealthSummary(
      steps: steps,
      caloriesBurned: calories,
      avgHeartRate: hrCount > 0 ? (avgHeartRate / hrCount) : 0,
      sleepHours: sleepMinutes / 60,
    );
  }

  /// Revoke access and clear stored preference.
  static Future<void> revokeAccess() async {
    try {
      await _health.revokePermissions();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}

/// Summary of today's health metrics.
class HealthSummary {
  final int steps;
  final double caloriesBurned;
  final double avgHeartRate;
  final double sleepHours;

  const HealthSummary({
    required this.steps,
    required this.caloriesBurned,
    required this.avgHeartRate,
    required this.sleepHours,
  });
}
