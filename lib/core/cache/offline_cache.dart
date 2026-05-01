import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight offline cache for critical data (treinos, exercícios).
///
/// Uses SharedPreferences for simplicity — JSON serialized.
/// TTL-based invalidation: cached data expires after [defaultTtl].
///
/// Usage:
///   await OfflineCache.put('treinos_aluno_42', jsonList);
///   final cached = await OfflineCache.get('treinos_aluno_42');
class OfflineCache {
  OfflineCache._();

  static const _prefix = 'fx_cache_';
  static const _tsPrefix = 'fx_cache_ts_';
  static const defaultTtl = Duration(hours: 4);

  /// Store [data] (must be JSON-encodable) under [key].
  static Future<void> put(String key, dynamic data, {Duration? ttl}) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(data);
    await prefs.setString('$_prefix$key', json);
    await prefs.setInt(
      '$_tsPrefix$key',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Retrieve cached data for [key], or null if expired/missing.
  static Future<T?> get<T>(String key, {Duration? ttl}) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_prefix$key');
    if (json == null) return null;

    final ts = prefs.getInt('$_tsPrefix$key');
    if (ts != null) {
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(ts),
      );
      if (age > (ttl ?? defaultTtl)) {
        // Expired — remove and return null
        await remove(key);
        return null;
      }
    }

    try {
      return jsonDecode(json) as T;
    } catch (_) {
      return null;
    }
  }

  /// Check if valid (non-expired) cache exists.
  static Future<bool> has(String key, {Duration? ttl}) async {
    final result = await get(key, ttl: ttl);
    return result != null;
  }

  /// Remove a specific cache entry.
  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
    await prefs.remove('$_tsPrefix$key');
  }

  /// Clear all cached data.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (k) => k.startsWith(_prefix) || k.startsWith(_tsPrefix),
    );
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
