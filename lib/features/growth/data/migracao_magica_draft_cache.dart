import 'package:shared_preferences/shared_preferences.dart';

import '../utils/migracao_magica_display.dart';

class MigracaoMagicaDraft {
  const MigracaoMagicaDraft({required this.text, required this.fonte});

  final String text;
  final MigracaoFonte fonte;
}

class MigracaoMagicaDraftCache {
  static const textKey = 'migracao_magica_draft_text';
  static const fonteKey = 'migracao_magica_draft_fonte';

  static Future<MigracaoMagicaDraft?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(textKey);
    if (text == null || text.trim().isEmpty) return null;
    final fonteName = prefs.getString(fonteKey);
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
    final prefs = await SharedPreferences.getInstance();
    if (text.trim().isEmpty) {
      await clear();
      return;
    }
    await prefs.setString(textKey, text);
    await prefs.setString(fonteKey, fonte.name);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(textKey);
    await prefs.remove(fonteKey);
  }
}
