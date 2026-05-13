import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepository(ref.read(apiClientProvider)),
);

final analyticsDashboardProvider = FutureProvider.autoDispose<
  AnalyticsDashboard
>((ref) async {
  final repo = ref.read(analyticsRepositoryProvider);

  // Fetch main dashboard + WAU + cohort in parallel for richer data
  final results = await Future.wait([
    repo.getDashboard(),
    repo.getWau().catchError((_) => <WauSemanal>[]),
    repo.getCohort().catchError((_) => <CohortRetencao>[]),
  ]);

  final dashboard = results[0] as AnalyticsDashboard;
  final wau = results[1] as List<WauSemanal>;
  final cohort = results[2] as List<CohortRetencao>;

  // Merge WAU and cohort into dashboard if the main endpoint didn't include them
  if (dashboard.evolucaoWau.isEmpty && wau.isNotEmpty) {
    return AnalyticsDashboard(
      totalAlunos: dashboard.totalAlunos,
      inadimplentes: dashboard.inadimplentes,
      wau: dashboard.wau,
      mau: dashboard.mau,
      taxaInadimplencia: dashboard.taxaInadimplencia,
      retencaoD7: dashboard.retencaoD7,
      retencaoD30: dashboard.retencaoD30,
      funil: dashboard.funil,
      evolucaoWau: wau,
      cohort: cohort.isNotEmpty ? cohort : dashboard.cohort,
    );
  }

  return dashboard;
});
