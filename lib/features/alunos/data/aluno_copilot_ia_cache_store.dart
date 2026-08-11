import '../../ia/models/ia_copilot_proxima_acao.dart';

/// Cache **em memória** da resposta IA do Copiloto (24h por aluno).
/// Não persiste em SharedPreferences (PII / conteúdo sensível).
class AlunoCopilotIaCacheStore {
  static const _ttl = Duration(hours: 24);

  static final Map<int, _Entry> _mem = {};

  static Future<IaCopilotProximaAcao?> loadIfFresh(int alunoId) async {
    final entry = _mem[alunoId];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.savedAt) > _ttl) {
      _mem.remove(alunoId);
      return null;
    }
    return entry.payload;
  }

  static Future<void> save(int alunoId, IaCopilotProximaAcao payload) async {
    _mem[alunoId] = _Entry(DateTime.now(), payload);
  }

  static Future<void> clear(int alunoId) async {
    _mem.remove(alunoId);
  }

  static Future<void> clearAll() async {
    _mem.clear();
  }
}

class _Entry {
  final DateTime savedAt;
  final IaCopilotProximaAcao payload;
  _Entry(this.savedAt, this.payload);
}
