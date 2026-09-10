import 'package:shared_preferences/shared_preferences.dart';

/// Slug do personal — sobrevive a logout (aluno precisa no login iOS).
abstract final class PersonalSlugStore {
  PersonalSlugStore._();

  static const _key = 'last_personal_slug';

  static Future<void> save(String? slug) async {
    final normalized = slug?.trim() ?? '';
    final prefs = await SharedPreferences.getInstance();
    if (normalized.isEmpty) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(_key, normalized);
  }

  static Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
