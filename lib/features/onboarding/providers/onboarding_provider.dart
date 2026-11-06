import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../planos/data/plano_features_bff_cache.dart';
import '../data/onboarding_repository.dart';
import '../data/onboarding_status_data.dart';
import '../data/onboarding_wizard_client_cache.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.read(apiClientProvider)),
);

final onboardingStatusProvider =
    FutureProvider.autoDispose<OnboardingStatusData>((ref) async {
      return ref.read(onboardingRepositoryProvider).getStatus();
    });

/// Concluir (ou pular) a ativação: avisa o servidor e derruba tudo que mostrava
/// o wizard: o próprio wizard, o status, os recursos do plano e a Home do
/// personal. Wizard e trava de recurso chamam daqui, sem lista própria.
Future<void> concluirOnboarding(WidgetRef ref) async {
  await ref.read(onboardingRepositoryProvider).marcarCompleto();
  OnboardingWizardClientCache.clear();
  PlanoFeaturesBffCache.clear();
  invalidatePersonalDashboardHome(ref);
  ref.invalidate(onboardingStatusProvider);
}
