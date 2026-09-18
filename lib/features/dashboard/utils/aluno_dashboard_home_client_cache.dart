import '../data/dashboard_repository.dart';

/// Cache client do BFF `/api/dashboard/aluno/home` (TTL BE = 60s).
///
/// SWR: após [ttl] ainda serve [staleTtl] e refresh em background.
abstract final class AlunoDashboardHomeClientCache {
  static const ttl = Duration(seconds: 60);
  static const staleTtl = Duration(minutes: 5);

  static AlunoDashboardHomeBundle? _bundle;
  static DateTime? _fetchedAt;
  static bool _refreshing = false;

  static AlunoDashboardHomeBundle? getIfFresh({DateTime? now}) {
    final bundle = _bundle;
    final at = _fetchedAt;
    if (bundle == null || at == null) return null;
    final age = (now ?? DateTime.now()).difference(at);
    if (age > ttl) return null;
    return bundle;
  }

  /// Serve expirado até [staleTtl] (stale-while-revalidate).
  static AlunoDashboardHomeBundle? getEvenIfStale({DateTime? now}) {
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

  static bool claimRefresh() {
    if (_refreshing) return false;
    _refreshing = true;
    return true;
  }

  static void releaseRefresh() => _refreshing = false;

  static void put(AlunoDashboardHomeBundle bundle, {DateTime? now}) {
    _bundle = bundle;
    _fetchedAt = now ?? DateTime.now();
  }

  static void clear() {
    _bundle = null;
    _fetchedAt = null;
    _refreshing = false;
  }

  static DateTime? get fetchedAt => _fetchedAt;
}
