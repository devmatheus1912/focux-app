import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const _keyToken = 'jwt_token';
  static const _keyRole = 'user_role';
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
    } else {
      await _storage.write(key: _keyToken, value: token);
    }
  }

  static Future<String?> getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyToken);
    }
    return _storage.read(key: _keyToken);
  }

  static Future<void> deleteToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
    } else {
      await _storage.delete(key: _keyToken);
    }
  }

  static Future<void> saveRole(String role) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRole, role);
    } else {
      await _storage.write(key: _keyRole, value: role);
    }
  }

  static Future<String?> getRole() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRole);
    }
    return _storage.read(key: _keyRole);
  }

  static Future<void> deleteRole() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRole);
    } else {
      await _storage.delete(key: _keyRole);
    }
  }

  static const _keyIsAdmin = 'is_admin';

  static Future<void> saveIsAdmin(bool value) async {
    final str = value ? 'true' : 'false';
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyIsAdmin, str);
    } else {
      await _storage.write(key: _keyIsAdmin, value: str);
    }
  }

  static Future<bool> getIsAdmin() async {
    String? val;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      val = prefs.getString(_keyIsAdmin);
    } else {
      val = await _storage.read(key: _keyIsAdmin);
    }
    return val == 'true';
  }

  static Future<void> deleteIsAdmin() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIsAdmin);
    } else {
      await _storage.delete(key: _keyIsAdmin);
    }
  }
}
