import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../ia/models/ia_copilot_proxima_acao.dart';

/// Cache local de resposta IA do Copiloto (24h por aluno).
class AlunoCopilotIaCacheStore {
  static const _ttl = Duration(hours: 24);

  static String _key(int alunoId) => 'aluno360_copilot_ia_$alunoId';

  static Future<IaCopilotProximaAcao?> loadIfFresh(int alunoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(alunoId));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(decoded['savedAt'] as String? ?? '');
      final payload = decoded['payload'];
      if (savedAt == null || payload is! Map) return null;
      if (DateTime.now().difference(savedAt) > _ttl) {
        await clear(alunoId);
        return null;
      }
      return IaCopilotProximaAcao.fromJson(
        Map<String, dynamic>.from(payload),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(int alunoId, IaCopilotProximaAcao payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(alunoId),
        jsonEncode({
          'savedAt': DateTime.now().toIso8601String(),
          'payload': payload.toJson(),
        }),
      );
    } catch (_) {}
  }

  static Future<void> clear(int alunoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(alunoId));
    } catch (_) {}
  }
}
