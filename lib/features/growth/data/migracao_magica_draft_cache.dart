import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/migracao_magica_display.dart';

class MigracaoMagicaDraft {
  const MigracaoMagicaDraft({required this.text, required this.fonte});

  final String text;
  final MigracaoFonte fonte;
}

/// Rascunho tem nome e telefone de alunos (PII): Keychain/Keystore no nativo,
/// só memória no web.
class MigracaoMagicaDraftCache {
  static const textKey = 'migracao_magica_draft_text';
  static const fonteKey = 'migracao_magica_draft_fonte';

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static String? _webText;
  static String? _webFonte;

  static Future<MigracaoMagicaDraft?> load() async {
    final text = kIsWeb ? _webText : await _storage.read(key: textKey);
    if (text == null || text.trim().isEmpty) return null;
    final fonteName = kIsWeb ? _webFonte : await _storage.read(key: fonteKey);
    final fonte = MigracaoFonte.values.firstWhere(
      (item) => item.name == fonteName,
      orElse: () => MigracaoFonte.texto,
    );
    return MigracaoMagicaDraft(text: text, fonte: fonte);
  }

  static Future<void> save({
    required String text,
    required MigracaoFonte fonte,
  }) async {
    if (text.trim().isEmpty) {
      await clear();
      return;
    }
    if (kIsWeb) {
      _webText = text;
      _webFonte = fonte.name;
      return;
    }
    await _storage.write(key: textKey, value: text);
    await _storage.write(key: fonteKey, value: fonte.name);
  }

  static Future<void> clear() async {
    _webText = null;
    _webFonte = null;
    if (!kIsWeb) {
      await _storage.delete(key: textKey);
      await _storage.delete(key: fonteKey);
    }
    // Versões antigas gravavam em SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(textKey);
    await prefs.remove(fonteKey);
  }
}
