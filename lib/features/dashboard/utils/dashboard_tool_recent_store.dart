import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'dashboard_tool_recent_routes';
const _maxRecent = 3;

/// Persiste rotas de atalhos abertos recentemente na Home.
class DashboardToolRecentStore {
  DashboardToolRecentStore._();

  static Future<void> recordRoute(String route) async {
    if (route.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_prefsKey) ?? <String>[];
    final next =
        <String>[
          route,
          ...current.where((r) => r != route),
        ].take(_maxRecent).toList();
    await prefs.setStringList(_prefsKey, next);
  }

  static Future<List<String>> loadRecentRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefsKey) ?? const <String>[];
  }
}
