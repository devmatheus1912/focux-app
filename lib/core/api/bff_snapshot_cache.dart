import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_etag_store.dart';

/// Snapshot em memória de um BFF (um bundle por rota): TTL alinhado ao
/// servidor, janela stale (stale-while-revalidate), sonda do ETag para o
/// `If-None-Match` e um refresh em segundo plano por vez.
///
/// Leia com [lerSnapshotBff]; limpe com [clear] junto do `ref.invalidate` do
/// provider (só invalidar devolveria o bundle velho até o TTL vencer).
class BffSnapshotCache<T> {
  BffSnapshotCache({
    required this.etagPath,
    required this.ttl,
    this.staleTtl = const Duration(minutes: 5),
    this.renovar,
  });

  final String etagPath;
  final Duration ttl;
  final Duration staleTtl;

  /// Cópia do bundle com a idade nova depois de um 304, para a tela saber que
  /// atualizou. Sem ela o mesmo bundle só ganha idade nova.
  final T Function(T bundle, DateTime at)? renovar;

  T? _bundle;
  DateTime? _fetchedAt;
  bool _refreshing = false;
  int _geracao = 0;
  bool _probeRegistered = false;

  void _ensureProbe() {
    if (_probeRegistered) return;
    _probeRegistered = true;
    ApiEtagStore.registerBodyProbe(etagPath, () => _bundle != null);
  }

  T? getIfFresh({DateTime? now}) {
    _ensureProbe();
    final bundle = _bundle;
    final at = _fetchedAt;
    if (bundle == null || at == null) return null;
    if ((now ?? DateTime.now()).difference(at) > ttl) return null;
    return bundle;
  }

  /// Serve expirado até [staleTtl]; depois disso limpa e devolve `null`.
  T? getEvenIfStale({DateTime? now}) {
    _ensureProbe();
    final bundle = _bundle;
    final at = _fetchedAt;
    if (bundle == null || at == null) return null;
    if ((now ?? DateTime.now()).difference(at) > staleTtl) {
      clear();
      return null;
    }
    return bundle;
  }

  /// Body presente (fresco ou stale): gate do If-None-Match.
  bool get hasBody {
    _ensureProbe();
    return _bundle != null;
  }

  bool claimRefresh() {
    if (_refreshing) return false;
    _refreshing = true;
    return true;
  }

  void releaseRefresh() => _refreshing = false;

  /// Sobe a cada [clear] (logout, troca de tenant, escrita que muda a Home).
  int get geracao => _geracao;

  /// Com [geracao], só grava se o cache não foi limpo desde que a busca
  /// começou: resposta da sessão anterior não volta depois do logout.
  void put(T bundle, {DateTime? now, int? geracao}) {
    if (geracao != null && geracao != _geracao) return;
    _ensureProbe();
    _bundle = bundle;
    _fetchedAt = now ?? DateTime.now();
  }

  /// 304: o servidor confirmou o bundle atual. Renova a idade.
  T? revalidar({DateTime? now}) {
    final bundle = getEvenIfStale(now: now);
    if (bundle == null) return null;
    final at = now ?? DateTime.now();
    final renovado = renovar == null ? bundle : renovar!(bundle, at);
    put(renovado, now: at);
    return renovado;
  }

  void clear() {
    _geracao++;
    _bundle = null;
    _fetchedAt = null;
    _refreshing = false;
    ApiEtagStore.removeForPath(method: 'GET', path: etagPath);
  }

  DateTime? get fetchedAt => _fetchedAt;
}

/// Leitura de um provider de BFF com [cache]: fresco direto; stale pinta já e
/// atualiza em segundo plano (uma vez); sem cache busca. [buscar] devolve
/// `null` no 304, que renova o bundle atual.
Future<T> lerSnapshotBff<T>(
  Ref ref,
  BffSnapshotCache<T> cache,
  Future<T?> Function() buscar,
) async {
  final freshHit = cache.getIfFresh();
  if (freshHit != null) return freshHit;

  final staleHit = cache.getEvenIfStale();
  if (staleHit != null && cache.claimRefresh()) {
    final geracao = cache.geracao;
    Future<void>(() async {
      try {
        final fresh = await buscar();
        if (geracao != cache.geracao) return;
        if (fresh != null) {
          cache.put(fresh);
        } else {
          cache.revalidar();
          // 304 sem cópia nova: o bundle na tela é o mesmo, sem rebuild.
          if (cache.renovar == null) return;
        }
        ref.invalidateSelf();
      } catch (_) {
        // Mantém stale.
      } finally {
        // Depois de um clear o claim já foi zerado e pode ser de outro refresh.
        if (geracao == cache.geracao) cache.releaseRefresh();
      }
    });
    return staleHit;
  }

  final geracao = cache.geracao;
  final fresh = await buscar();
  if (fresh != null) {
    cache.put(fresh, geracao: geracao);
    return fresh;
  }
  final stale = cache.revalidar();
  if (stale != null) return stale;
  // 304 órfão (sem body local): o repositório já tenta de novo sem ETag.
  final recovered = await buscar();
  if (recovered != null) {
    cache.put(recovered, geracao: geracao);
    return recovered;
  }
  throw StateError('GET ${cache.etagPath}: resposta vazia');
}
