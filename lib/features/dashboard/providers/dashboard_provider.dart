import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../data/command_center_data.dart';
import '../data/dashboard_repository.dart';
import '../utils/dashboard_home_client_cache.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.read(apiClientProvider)),
);

/// Single BFF call for personal Home (personal + command center + financeiro).
/// Respeita TTL client 90s (= cache BE `dashboard-home`); `invalidate` limpa.
final dashboardHomeProvider = FutureProvider<DashboardHomeBundle>((ref) async {
  // Não limpar cache no dispose — invalidate pós-login/recarrega descartava o
  // prefetch e pintava "Algo saiu do ar". Limpeza só no logout/tenant switch.
  final cached = DashboardHomeClientCache.getIfFresh();
  if (cached != null) return cached;
  final fresh = await ref.read(dashboardRepositoryProvider).getHome();
  DashboardHomeClientCache.put(fresh);
  return fresh;
});

/// Home BFF do aluno — `GET /api/dashboard/aluno/home` (TTL client 60s).
final alunoDashboardHomeProvider =
    FutureProvider<AlunoDashboardHomeBundle>((ref) async {
  return ref.read(dashboardRepositoryProvider).getAlunoHome();
});

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  return (await ref.watch(dashboardHomeProvider.future)).personal;
});

final commandCenterProvider = FutureProvider<CommandCenterData>((ref) async {
  return (await ref.watch(dashboardHomeProvider.future)).commandCenter;
});
