import 'package:shared_preferences/shared_preferences.dart';

/// Persistência opcional do focus mode da Home.
abstract final class DashboardHomeFocusStore {
  DashboardHomeFocusStore._();

  static const _key = 'focux_home_focus_mode_v1';

  static Future<bool?> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_key)) return null;
    return prefs.getBool(_key);
  }

  static Future<void> save(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}
