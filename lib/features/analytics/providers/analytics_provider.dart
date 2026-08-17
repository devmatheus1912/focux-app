import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepository(ref.read(apiClientProvider)),
);

final analyticsDashboardProvider = FutureProvider.autoDispose<
  AnalyticsDashboard
>((ref) async {
  return ref.read(analyticsRepositoryProvider).getDashboard();
});
