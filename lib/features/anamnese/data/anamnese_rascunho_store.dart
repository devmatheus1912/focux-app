import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Ficha em andamento no aparelho. É dado de saúde: só no Keychain/Keystore,
/// nunca em SharedPreferences, e sai no envio e no logout.
abstract final class AnamneseRascunhoStore {
  static const _key = 'anamnese_rascunho_v1';
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<Map<String, dynamic>?> ler() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> salvar(Map<String, dynamic> dados) async {
    try {
      await _storage.write(key: _key, value: jsonEncode(dados));
    } catch (_) {
      // Rascunho é conveniência: falhar não atrapalha o preenchimento.
    }
  }

  static Future<void> limpar() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}
