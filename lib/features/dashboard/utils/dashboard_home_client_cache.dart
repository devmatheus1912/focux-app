import '../data/dashboard_repository.dart';

/// Cache client do BFF `/home` alinhado ao TTL BE (`dashboard-home` = 90s).
abstract final class DashboardHomeClientCache {
  static const ttl = Duration(seconds: 90);

  static DashboardHomeBundle? _bundle;
  static DateTime? _fetchedAt;

  static DashboardHomeBundle? getIfFresh({DateTime? now}) {
    final bundle = _bundle;
    final at = _fetchedAt;
    if (bundle == null || at == null) return null;
    final age = (now ?? DateTime.now()).difference(at);
    if (age > ttl) return null;
    return bundle;
  }

  static void put(DashboardHomeBundle bundle, {DateTime? now}) {
    _bundle = bundle;
    _fetchedAt = now ?? DateTime.now();
  }

  static void clear() {
    _bundle = null;
    _fetchedAt = null;
  }

  static DateTime? get fetchedAt => _fetchedAt;
}
