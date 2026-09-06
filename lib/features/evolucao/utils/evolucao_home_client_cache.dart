import '../data/evolucao_repository.dart';

/// Short in-memory cache for `GET /api/alunos/{id}/evolucao/home`.
///
/// Keeps Ferramentas → Medidas from cold-fetching on every open.
abstract final class EvolucaoHomeClientCache {
  static const ttl = Duration(seconds: 45);

  static final _entries = <int, ({EvolucaoHomeBundle bundle, DateTime at})>{};

  static EvolucaoHomeBundle? getIfFresh(int alunoId, {DateTime? now}) {
    final hit = _entries[alunoId];
    if (hit == null) return null;
    if ((now ?? DateTime.now()).difference(hit.at) > ttl) {
      _entries.remove(alunoId);
      return null;
    }
    return hit.bundle;
  }

  static void put(int alunoId, EvolucaoHomeBundle bundle, {DateTime? now}) {
    _entries[alunoId] = (bundle: bundle, at: now ?? DateTime.now());
  }

  static void invalidate(int alunoId) => _entries.remove(alunoId);

  static void clear() => _entries.clear();
}
