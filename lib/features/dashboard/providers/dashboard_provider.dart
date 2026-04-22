import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/command_center_data.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.read(apiClientProvider)),
);

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  return ref.read(dashboardRepositoryProvider).getDashboard();
});

final commandCenterProvider = FutureProvider<CommandCenterData>((ref) async {
  return ref.read(dashboardRepositoryProvider).getCommandCenter();
});
