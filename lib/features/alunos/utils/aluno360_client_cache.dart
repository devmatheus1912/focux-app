import '../data/aluno_repository.dart';

/// Short in-memory caches for progressive Aluno 360 endpoints.
/// Aligned with server-side aluno-360 TTL (~30–60s).
abstract final class Aluno360ClientCache {
  static const ttl = Duration(seconds: 45);

  static final _operacao = <int, ({Aluno360Operacao bundle, DateTime at})>{};
  static final _evolucao = <int, ({Aluno360Evolucao bundle, DateTime at})>{};
  static final _ferramentas =
      <int, ({Aluno360Ferramentas bundle, DateTime at})>{};

  /// Legacy monolito `/360` — kept for invalidate compatibility only.
  static final _legacy = <int, ({Aluno360 bundle, DateTime at})>{};

  static Aluno360Operacao? getOperacaoIfFresh(int alunoId, {DateTime? now}) {
    final hit = _operacao[alunoId];
    if (hit == null) return null;
    if ((now ?? DateTime.now()).difference(hit.at) > ttl) {
      _operacao.remove(alunoId);
      return null;
    }
    return hit.bundle;
  }

  static void putOperacao(int alunoId, Aluno360Operacao bundle, {DateTime? now}) {
    _operacao[alunoId] = (bundle: bundle, at: now ?? DateTime.now());
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
    _evolucao[alunoId] = (bundle: bundle, at: now ?? DateTime.now());
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
    _ferramentas[alunoId] = (bundle: bundle, at: now ?? DateTime.now());
  }

  @Deprecated('Use getOperacaoIfFresh — monolito /360 saiu do first paint')
  static Aluno360? getIfFresh(int alunoId, {DateTime? now}) {
    final hit = _legacy[alunoId];
    if (hit == null) return null;
    if ((now ?? DateTime.now()).difference(hit.at) > ttl) {
      _legacy.remove(alunoId);
      return null;
    }
    return hit.bundle;
  }

  @Deprecated('Use putOperacao — monolito /360 saiu do first paint')
  static void put(int alunoId, Aluno360 bundle, {DateTime? now}) {
    _legacy[alunoId] = (bundle: bundle, at: now ?? DateTime.now());
  }

  static void invalidate(int alunoId) {
    _operacao.remove(alunoId);
    _evolucao.remove(alunoId);
    _ferramentas.remove(alunoId);
    _legacy.remove(alunoId);
  }

  static void clear() {
    _operacao.clear();
    _evolucao.clear();
    _ferramentas.clear();
    _legacy.clear();
  }
}
