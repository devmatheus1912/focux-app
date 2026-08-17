import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/financeiro_repository.dart';

final financeiroRepositoryProvider = Provider<FinanceiroRepository>(
  (ref) => FinanceiroRepository(ref.read(apiClientProvider)),
);

/// Single BFF call for Financeiro first paint.
final financeiroHomeProvider = FutureProvider<FinanceiroHomeBundle>((ref) async {
  return ref.read(financeiroRepositoryProvider).getHome();
});

/// Invalida BFF Financeiro + Home Personal (mesmo SSOT de dashboard).
void invalidateFinanceiroCaches(WidgetRef ref) {
  ref.invalidate(financeiroHomeProvider);
  ref.invalidate(dashboardHomeProvider);
}
