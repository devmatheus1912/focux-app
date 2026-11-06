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

  void put(T bundle, {DateTime? now}) {
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
    Future<void>(() async {
      try {
        final fresh = await buscar();
        if (fresh != null) {
          cache.put(fresh);
        } else {
          cache.revalidar();
        }
        ref.invalidateSelf();
      } catch (_) {
        // Mantém stale.
      } finally {
        cache.releaseRefresh();
      }
    });
    return staleHit;
  }

  final fresh = await buscar();
  if (fresh != null) {
    cache.put(fresh);
    return fresh;
  }
  final stale = cache.revalidar();
  if (stale != null) return stale;
  // 304 órfão (sem body local): o repositório já tenta de novo sem ETag.
  final recovered = await buscar();
  if (recovered != null) {
    cache.put(recovered);
    return recovered;
  }
  throw StateError('GET ${cache.etagPath}: resposta vazia');
}
