import '../data/aluno_repository.dart';

/// Short in-memory caches for progressive Aluno 360 endpoints.
/// Aligned with server-side aluno-360 TTL (~30–60s).
abstract final class Aluno360ClientCache {
  static const ttl = Duration(seconds: 45);

  /// Soft window: serve expired Operação and refresh in background.
  static const staleTtl = Duration(minutes: 5);

  static final _operacao = <int, ({Aluno360Operacao bundle, DateTime at})>{};
  static final _evolucao = <int, ({Aluno360Evolucao bundle, DateTime at})>{};
  static final _ferramentas =
      <int, ({Aluno360Ferramentas bundle, DateTime at})>{};
  static final _operacaoRefreshing = <int>{};

  /// Mapa ordenado por inserção: re-put move p/ o fim, estouro tira o mais velho.
  static const maxEntries = 40;

  static void _put<T>(Map<int, T> map, int alunoId, T value) {
    map.remove(alunoId);
    map[alunoId] = value;
    if (map.length > maxEntries) map.remove(map.keys.first);
  }

  static Aluno360Operacao? getOperacaoIfFresh(int alunoId, {DateTime? now}) {
    final hit = _operacao[alunoId];
    if (hit == null) return null;
    if ((now ?? DateTime.now()).difference(hit.at) > ttl) {
      return null;
    }
    return hit.bundle;
  }

  /// Returns Operação even after [ttl], until [staleTtl] elapses.
  static Aluno360Operacao? getOperacaoEvenIfStale(
    int alunoId, {
    DateTime? now,
  }) {
    final hit = _operacao[alunoId];
    if (hit == null) return null;
    if ((now ?? DateTime.now()).difference(hit.at) > staleTtl) {
      _operacao.remove(alunoId);
      return null;
    }
    return hit.bundle;
  }

  /// Claims background refresh slot for [alunoId] (dedupes concurrent SWR).
  static bool claimOperacaoRefresh(int alunoId) =>
      _operacaoRefreshing.add(alunoId);

  static void releaseOperacaoRefresh(int alunoId) =>
      _operacaoRefreshing.remove(alunoId);

  static void putOperacao(int alunoId, Aluno360Operacao bundle, {DateTime? now}) {
    _put(_operacao, alunoId, (bundle: bundle, at: now ?? DateTime.now()));
  }

  static Aluno360Evolucao? getEvolucaoIfFresh(int alunoId, {DateTime? now}) {
    final hit = _evolucao[alunoId];
    if (hit == null) return null;
    if ((now ?? DateTime.now()).difference(hit.at) > ttl) {
      _evolucao.remove(alunoId);
      return null;
    }
    return hit.bundle;
  }

  static void putEvolucao(int alunoId, Aluno360Evolucao bundle, {DateTime? now}) {
    _put(_evolucao, alunoId, (bundle: bundle, at: now ?? DateTime.now()));
  }

  static Aluno360Ferramentas? getFerramentasIfFresh(
    int alunoId, {
    DateTime? now,
  }) {
    final hit = _ferramentas[alunoId];
    if (hit == null) return null;
    if ((now ?? DateTime.now()).difference(hit.at) > ttl) {
      _ferramentas.remove(alunoId);
      return null;
    }
    return hit.bundle;
  }

  static void putFerramentas(
    int alunoId,
    Aluno360Ferramentas bundle, {
    DateTime? now,
  }) {
    _put(_ferramentas, alunoId, (bundle: bundle, at: now ?? DateTime.now()));
  }

  static void invalidate(int alunoId) {
    _operacao.remove(alunoId);
    _evolucao.remove(alunoId);
    _ferramentas.remove(alunoId);
    _operacaoRefreshing.remove(alunoId);
  }

  static void clear() {
    _operacao.clear();
    _evolucao.clear();
    _ferramentas.clear();
    _operacaoRefreshing.clear();
  }
}
