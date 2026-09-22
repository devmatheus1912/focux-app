import 'checkin_repository.dart';

/// Lista do histórico em memória (sem disco).
class HistoricoMemCache {
  HistoricoMemCache._();

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

  static void save(List<ExecucaoTreino> items) {
    _items = List.unmodifiable(items);
    _savedAt = DateTime.now();
  }

  static void clear() {
    _items = null;
    _savedAt = null;
  }
}

class HistoricoDetalheMemCache {
  HistoricoDetalheMemCache._();

  static final _byId = <int, ExecucaoTreino>{};
  static final _savedAt = <int, DateTime>{};
  static const ttl = Duration(hours: 4);

  static ExecucaoTreino? loadIfFresh(int id) {
    final at = _savedAt[id];
    final item = _byId[id];
    if (at == null || item == null) return null;
    if (DateTime.now().difference(at) > ttl) {
      _byId.remove(id);
      _savedAt.remove(id);
      return null;
    }
    return item;
  }

  static void save(ExecucaoTreino execucao) {
    final id = execucao.id;
    if (id == null) return;
    _byId[id] = execucao;
    _savedAt[id] = DateTime.now();
  }
}
