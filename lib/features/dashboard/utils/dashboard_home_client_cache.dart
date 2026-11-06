import '../../../core/api/bff_snapshot_cache.dart';
import '../data/dashboard_repository.dart';

/// BFF `/api/dashboard/home` do personal, TTL do servidor (`dashboard-home` = 90 s).
final dashboardHomeClientCache = BffSnapshotCache<DashboardHomeBundle>(
  etagPath: '/api/dashboard/home',
  ttl: const Duration(seconds: 90),
);
