import '../../../core/api/api_etag_store.dart';
import '../data/dashboard_repository.dart';

/// Cache client do BFF `/api/dashboard/aluno/home` (TTL BE = 60s).
///
/// SWR: após [ttl] ainda serve [staleTtl] e refresh em background.
abstract final class AlunoDashboardHomeClientCache {
  static const ttl = Duration(seconds: 60);
  static const staleTtl = Duration(minutes: 5);
  static const etagPath = '/api/dashboard/aluno/home';

  static AlunoDashboardHomeBundle? _bundle;
  static DateTime? _fetchedAt;
  static bool _refreshing = false;
  static bool _probeRegistered = false;

  static void _ensureProbe() {
    if (_probeRegistered) return;
    _probeRegistered = true;
    ApiEtagStore.registerBodyProbe(etagPath, () => _bundle != null);
  }

  static AlunoDashboardHomeBundle? getIfFresh({DateTime? now}) {
    _ensureProbe();
    final bundle = _bundle;
    final at = _fetchedAt;
    if (bundle == null || at == null) return null;
    final age = (now ?? DateTime.now()).difference(at);
    if (age > ttl) return null;
    return bundle;
  }

  /// Serve expirado até [staleTtl] (stale-while-revalidate).
  static AlunoDashboardHomeBundle? getEvenIfStale({DateTime? now}) {
    _ensureProbe();
    final bundle = _bundle;
    final at = _fetchedAt;
    if (bundle == null || at == null) return null;
    final age = (now ?? DateTime.now()).difference(at);
    if (age > staleTtl) {
      clear();
      return null;
    }
    return bundle;
  }

  /// Body presente (fresco ou stale) — gate do If-None-Match.
  static bool get hasBody {
    _ensureProbe();
    return _bundle != null;
  }

  static bool claimRefresh() {
    if (_refreshing) return false;
    _refreshing = true;
    return true;
  }

  static void releaseRefresh() => _refreshing = false;

  static void put(AlunoDashboardHomeBundle bundle, {DateTime? now}) {
    _ensureProbe();
    _bundle = bundle;
    _fetchedAt = now ?? DateTime.now();
  }

  static void clear() {
    _bundle = null;
    _fetchedAt = null;
    _refreshing = false;
    ApiEtagStore.removeForPath(method: 'GET', path: etagPath);
  }

  static DateTime? get fetchedAt => _fetchedAt;
}
