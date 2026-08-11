import 'checkin_repository.dart';

/// Cache em memória de treinos do aluno (sem disco — evita PII/saúde em prefs).
class MeusTreinosMemCache {
  MeusTreinosMemCache._();

  static List<ExecucaoTreino>? _items;
  static DateTime? _savedAt;
  static const ttl = Duration(hours: 4);

  static List<ExecucaoTreino>? loadIfFresh() {
    if (_items == null || _savedAt == null) return null;
    if (DateTime.now().difference(_savedAt!) > ttl) {
      clear();
      return null;
    }
    return _items;
  }

  static void save(List<ExecucaoTreino> treinos) {
    _items = List.unmodifiable(treinos);
    _savedAt = DateTime.now();
  }

  static void clear() {
    _items = null;
    _savedAt = null;
  }
}
