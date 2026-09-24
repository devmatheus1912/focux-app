import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const _keyToken = 'jwt_token';
  static const _keyRefreshToken = 'jwt_refresh_token';
  static const _keyRole = 'user_role';
  static const _keyRequiresPasswordChange = 'requires_password_change';

  /// Memória no web (evita JWT em localStorage). Nativo: Keystore/Keychain.
  static String? _webAccessToken;
  static String? _webRefreshToken;
  static String? _webRole;
  static String? _webRequiresPasswordChange;

  /// Cache RAM nativo — evita Keychain/Keystore a cada Dio/redirect.
  /// Invalidado em save/delete/clearAll.
  static String? _memAccessToken;
  static String? _memRefreshToken;
  static String? _memRole;
  static String? _memRequiresPasswordChange;
  static bool _memAccessLoaded = false;
  static bool _memRefreshLoaded = false;
  static bool _memRoleLoaded = false;
  static bool _memRequiresLoaded = false;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Só testes — zera caches de memória sem tocar no Keychain.
  @visibleForTesting
  static void debugResetMemoryCache() {
    _webAccessToken = null;
    _webRefreshToken = null;
    _webRole = null;
    _webRequiresPasswordChange = null;
    _clearNativeMemory();
  }

  /// Só testes — simula nativo já aquecido (sem I/O).
  @visibleForTesting
  static void debugPrimeNativeCache({
    String? token,
    String? refreshToken,
    String? role,
    bool? requiresPasswordChange,
  }) {
    _memAccessToken = token;
    _memAccessLoaded = true;
    _memRefreshToken = refreshToken;
    _memRefreshLoaded = true;
    _memRole = role;
    _memRoleLoaded = true;
    _memRequiresPasswordChange =
        requiresPasswordChange == null
            ? null
            : (requiresPasswordChange ? 'true' : 'false');
    _memRequiresLoaded = true;
  }

  static void _clearNativeMemory() {
    _memAccessToken = null;
    _memRefreshToken = null;
    _memRole = null;
    _memRequiresPasswordChange = null;
    _memAccessLoaded = false;
    _memRefreshLoaded = false;
    _memRoleLoaded = false;
    _memRequiresLoaded = false;
  }

  /// Prefetch Keychain → RAM (token/role/refresh/requires) em paralelo ao boot.
  static Future<void> warmSessionCache() async {
    if (kIsWeb) return;
    await Future.wait<void>([
      getToken().then((_) {}),
      getRole().then((_) {}),
      getRefreshToken().then((_) {}),
      getRequiresPasswordChange().then((_) {}),
    ]);
  }

  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      _webAccessToken = token;
      return;
    }
    _memAccessToken = token;
    _memAccessLoaded = true;
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<String?> getToken() async {
    if (kIsWeb) return _webAccessToken;
    if (_memAccessLoaded) return _memAccessToken;
    _memAccessToken = await _storage.read(key: _keyToken);
    _memAccessLoaded = true;
    return _memAccessToken;
  }

  static Future<void> deleteToken() async {
    if (kIsWeb) {
      _webAccessToken = null;
      return;
    }
    _memAccessToken = null;
    _memAccessLoaded = true;
    await _storage.delete(key: _keyToken);
  }

  static Future<void> saveRole(String role) async {
    if (kIsWeb) {
      _webRole = role;
      return;
    }
    _memRole = role;
    _memRoleLoaded = true;
    await _storage.write(key: _keyRole, value: role);
  }

  static Future<String?> getRole() async {
    if (kIsWeb) return _webRole;
    if (_memRoleLoaded) return _memRole;
    _memRole = await _storage.read(key: _keyRole);
    _memRoleLoaded = true;
    return _memRole;
  }

  static Future<void> deleteRole() async {
    if (kIsWeb) {
      _webRole = null;
      return;
    }
    _memRole = null;
    _memRoleLoaded = true;
    await _storage.delete(key: _keyRole);
  }

  static Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      _webRefreshToken = token;
      return;
    }
    _memRefreshToken = token;
    _memRefreshLoaded = true;
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  static Future<String?> getRefreshToken() async {
    if (kIsWeb) return _webRefreshToken;
    if (_memRefreshLoaded) return _memRefreshToken;
    _memRefreshToken = await _storage.read(key: _keyRefreshToken);
    _memRefreshLoaded = true;
    return _memRefreshToken;
  }

  static Future<void> deleteRefreshToken() async {
    if (kIsWeb) {
      _webRefreshToken = null;
      return;
    }
    _memRefreshToken = null;
    _memRefreshLoaded = true;
    await _storage.delete(key: _keyRefreshToken);
  }

  static Future<void> saveRequiresPasswordChange(bool value) async {
    final str = value ? 'true' : 'false';
    if (kIsWeb) {
      _webRequiresPasswordChange = str;
      return;
    }
    _memRequiresPasswordChange = str;
    _memRequiresLoaded = true;
    await _storage.write(key: _keyRequiresPasswordChange, value: str);
  }

  static Future<bool> getRequiresPasswordChange() async {
    if (kIsWeb) return _webRequiresPasswordChange == 'true';
    if (_memRequiresLoaded) {
      return _memRequiresPasswordChange == 'true';
    }
    final val = await _storage.read(key: _keyRequiresPasswordChange);
    _memRequiresPasswordChange = val;
    _memRequiresLoaded = true;
    return val == 'true';
  }

  static Future<void> deleteRequiresPasswordChange() async {
    if (kIsWeb) {
      _webRequiresPasswordChange = null;
      return;
    }
    _memRequiresPasswordChange = null;
    _memRequiresLoaded = true;
    await _storage.delete(key: _keyRequiresPasswordChange);
  }

  static Future<void> clearAll() async {
    if (kIsWeb) {
      _webAccessToken = null;
      _webRefreshToken = null;
      _webRole = null;
      _webRequiresPasswordChange = null;
      // Limpa legado em SharedPreferences (versões antigas).
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyRole);
      await prefs.remove('is_admin');
      await prefs.remove(_keyRequiresPasswordChange);
      return;
    }
    _clearNativeMemory();
    await _storage.deleteAll();
  }
}
