import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dunning/data/dunning_repository.dart';
import '../data/financeiro_repository.dart';

final financeiroRepositoryProvider = Provider<FinanceiroRepository>(
  (ref) => FinanceiroRepository(ref.read(apiClientProvider)),
);

/// Single BFF call for Financeiro first paint.
final financeiroHomeProvider = FutureProvider<FinanceiroHomeBundle>((
  ref,
) async {
  return ref.read(financeiroRepositoryProvider).getHome();
});

/// Estado da cobrança automática (falhas abertas) para a linha do Financeiro.
final financeiroCobrancaAutoProvider =
    FutureProvider.autoDispose<DunningSnapshot>((ref) async {
      final bundle = await DunningRepository(
        ref.read(apiClientProvider),
      ).getHome(size: 1);
      return bundle.snapshot;
    });

/// Invalida BFF Financeiro + Home Personal (mesmo SSOT de dashboard).
void invalidateFinanceiroCaches(WidgetRef ref) {
  ref.invalidate(financeiroHomeProvider);
  ref.invalidate(dashboardHomeProvider);
}
