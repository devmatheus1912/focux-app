import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/onboarding_repository.dart';
import '../data/onboarding_status_data.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.read(apiClientProvider)),
);

final onboardingStatusProvider =
    FutureProvider.autoDispose<OnboardingStatusData>((ref) async {
      return ref.read(onboardingRepositoryProvider).getStatus();
    });
