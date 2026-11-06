import '../../../core/api/bff_snapshot_cache.dart';
import '../data/dashboard_repository.dart';

/// BFF `/api/dashboard/aluno/home`, TTL do servidor (60 s). O 304 devolve uma
/// cópia com a idade nova, para a tela saber que atualizou.
final alunoDashboardHomeClientCache = BffSnapshotCache<AlunoDashboardHomeBundle>(
  etagPath: '/api/dashboard/aluno/home',
  ttl: const Duration(seconds: 60),
  renovar: (bundle, at) => bundle.withFetchedAt(at),
);
