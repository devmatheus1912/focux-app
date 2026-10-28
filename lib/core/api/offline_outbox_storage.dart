import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onde a fila de mutações offline fica gravada. O corpo das requisições (medidas de saúde, dados
/// do perfil) não pode ficar em texto puro em SharedPreferences: no aparelho ele vai para o
/// Keychain/Keystore ([SecureOutboxStorage]).
abstract class OfflineOutboxStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);

  /// Padrão: cofre do sistema no aparelho; SharedPreferences na web e nos testes (sem plugin nativo).
  static OfflineOutboxStorage padrao() {
    final semCofre = kIsWeb || Platform.environment.containsKey('FLUTTER_TEST');
    return semCofre ? PrefsOutboxStorage() : SecureOutboxStorage();
  }
}

class SecureOutboxStorage implements OfflineOutboxStorage {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read(String key) async {
    final valor = await _storage.read(key: key);
    if (valor != null) return valor;
    // Resto de versões antigas: lê uma vez do texto puro, passa para o cofre e apaga o original.
    final prefs = await SharedPreferences.getInstance();
    final legado = prefs.getString(key);
    if (legado != null) {
      await _storage.write(key: key, value: legado);
      await prefs.remove(key);
    }
    return legado;
  }

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> remove(String key) async {
    await _storage.delete(key: key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}

class PrefsOutboxStorage implements OfflineOutboxStorage {
  @override
  Future<String?> read(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String key, String value) async {
    await (await SharedPreferences.getInstance()).setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await (await SharedPreferences.getInstance()).remove(key);
  }
}
