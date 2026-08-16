import 'package:shared_preferences/shared_preferences.dart';

/// First-run coach da Home (catálogo / radar).
abstract final class DashboardHomeCoachStore {
  static const _key = 'focux_home_coach_v1';

  static Future<bool> loadSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
