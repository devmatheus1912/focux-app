import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const _keyToken = 'jwt_token';
  static const _keyRefreshToken = 'jwt_refresh_token';
  static const _keyRole = 'user_role';
  static const _keyRequiresPasswordChange = 'requires_password_change';
  static const _keyIsAdmin = 'is_admin';

  /// Memória no web (evita JWT em localStorage). Nativo: Keystore/Keychain.
  static String? _webAccessToken;
  static String? _webRefreshToken;
  static String? _webRole;
  static String? _webIsAdmin;
  static String? _webRequiresPasswordChange;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      _webAccessToken = token;
      return;
    }
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<String?> getToken() async {
    if (kIsWeb) return _webAccessToken;
    return _storage.read(key: _keyToken);
  }

  static Future<void> deleteToken() async {
    if (kIsWeb) {
      _webAccessToken = null;
      return;
    }
    await _storage.delete(key: _keyToken);
  }

  static Future<void> saveRole(String role) async {
    if (kIsWeb) {
      _webRole = role;
      return;
    }
    await _storage.write(key: _keyRole, value: role);
  }

  static Future<String?> getRole() async {
    if (kIsWeb) return _webRole;
    return _storage.read(key: _keyRole);
  }

  static Future<void> deleteRole() async {
    if (kIsWeb) {
      _webRole = null;
      return;
    }
    await _storage.delete(key: _keyRole);
  }

  static Future<void> saveIsAdmin(bool value) async {
    final str = value ? 'true' : 'false';
    if (kIsWeb) {
      _webIsAdmin = str;
      return;
    }
    await _storage.write(key: _keyIsAdmin, value: str);
  }

  static Future<bool> getIsAdmin() async {
    if (kIsWeb) return _webIsAdmin == 'true';
    final val = await _storage.read(key: _keyIsAdmin);
    return val == 'true';
  }

  static Future<void> deleteIsAdmin() async {
    if (kIsWeb) {
      _webIsAdmin = null;
      return;
    }
    await _storage.delete(key: _keyIsAdmin);
  }

  static Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      _webRefreshToken = token;
      return;
    }
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  static Future<String?> getRefreshToken() async {
    if (kIsWeb) return _webRefreshToken;
    return _storage.read(key: _keyRefreshToken);
  }

  static Future<void> deleteRefreshToken() async {
    if (kIsWeb) {
      _webRefreshToken = null;
      return;
    }
    await _storage.delete(key: _keyRefreshToken);
  }

  static Future<void> saveRequiresPasswordChange(bool value) async {
    final str = value ? 'true' : 'false';
    if (kIsWeb) {
      _webRequiresPasswordChange = str;
      return;
    }
    await _storage.write(key: _keyRequiresPasswordChange, value: str);
  }

  static Future<bool> getRequiresPasswordChange() async {
    if (kIsWeb) return _webRequiresPasswordChange == 'true';
    final val = await _storage.read(key: _keyRequiresPasswordChange);
    return val == 'true';
  }

  static Future<void> deleteRequiresPasswordChange() async {
    if (kIsWeb) {
      _webRequiresPasswordChange = null;
      return;
    }
    await _storage.delete(key: _keyRequiresPasswordChange);
  }

  static Future<void> clearAll() async {
    if (kIsWeb) {
      _webAccessToken = null;
      _webRefreshToken = null;
      _webRole = null;
      _webIsAdmin = null;
      _webRequiresPasswordChange = null;
      // Limpa legado em SharedPreferences (versões antigas).
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyRole);
      await prefs.remove(_keyIsAdmin);
      await prefs.remove(_keyRequiresPasswordChange);
      return;
    }
    await _storage.deleteAll();
  }
}
