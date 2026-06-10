import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../data/command_center_data.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.read(apiClientProvider)),
);

/// Single BFF call for personal Home (personal + command center + financeiro).
final dashboardHomeProvider = FutureProvider<DashboardHomeBundle>((ref) async {
  return ref.read(dashboardRepositoryProvider).getHome();
});

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  return (await ref.watch(dashboardHomeProvider.future)).personal;
});

final commandCenterProvider = FutureProvider<CommandCenterData>((ref) async {
  return (await ref.watch(dashboardHomeProvider.future)).commandCenter;
});

final dashboardFinanceiroProvider = FutureProvider<FinanceiroDashboard>((
  ref,
) async {
  return (await ref.watch(dashboardHomeProvider.future)).financeiro;
});
