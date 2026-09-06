import '../data/aluno_repository.dart';

/// Short in-memory cache for GET `/api/alunos/{id}/360`.
/// Aligned with server-side aluno-360 TTL (~30–60s).
abstract final class Aluno360ClientCache {
  static const ttl = Duration(seconds: 45);

  static final _entries = <int, ({Aluno360 bundle, DateTime at})>{};

  static Aluno360? getIfFresh(int alunoId, {DateTime? now}) {
    final hit = _entries[alunoId];
    if (hit == null) return null;
    if ((now ?? DateTime.now()).difference(hit.at) > ttl) {
      _entries.remove(alunoId);
      return null;
    }
    return hit.bundle;
  }

  static void put(int alunoId, Aluno360 bundle, {DateTime? now}) {
    _entries[alunoId] = (bundle: bundle, at: now ?? DateTime.now());
  }

  static void invalidate(int alunoId) => _entries.remove(alunoId);

  static void clear() => _entries.clear();
}
