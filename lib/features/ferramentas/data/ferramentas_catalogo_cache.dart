import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'ferramentas_catalogo_models.dart';

const _prefsJsonKey = 'ferramentas_catalogo_json_v1';
const _prefsVersionKey = 'ferramentas_catalogo_version_v1';

/// Cache local do catálogo — invalida quando `version` do BFF muda.
class FerramentasCatalogoCache {
  FerramentasCatalogoCache._();

  static Future<FerramentasCatalogo?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsJsonKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return FerramentasCatalogo.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<int?> loadStoredVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsVersionKey);
  }

  static Future<void> save(FerramentasCatalogo catalogo, Map<String, dynamic> raw) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_prefsVersionKey);
    if (stored != null && stored != catalogo.version) {
      await prefs.remove(_prefsJsonKey);
    }
    await prefs.setString(_prefsJsonKey, jsonEncode(raw));
    await prefs.setInt(_prefsVersionKey, catalogo.version);
  }

  static Future<void> invalidateIfVersionChanged(int remoteVersion) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_prefsVersionKey);
    if (stored != null && stored != remoteVersion) {
      await prefs.remove(_prefsJsonKey);
      await prefs.setInt(_prefsVersionKey, remoteVersion);
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsJsonKey);
    await prefs.remove(_prefsVersionKey);
  }
}
