import '../../dashboard/utils/dashboard_home_client_cache.dart';
import 'onboarding_repository.dart';

/// Cache client do wizard, mesmo TTL da Home (90s).
abstract final class OnboardingWizardClientCache {
  static const ttl = DashboardHomeClientCache.ttl;

  static OnboardingWizard? _wizard;
  static DateTime? _fetchedAt;

  static OnboardingWizard? getIfFresh({DateTime? now}) {
    final wizard = _wizard;
    final at = _fetchedAt;
    if (wizard == null || at == null) return null;
    final age = (now ?? DateTime.now()).difference(at);
    if (age > ttl) return null;
    return wizard;
  }

  static void put(OnboardingWizard wizard, {DateTime? now}) {
    _wizard = wizard;
    _fetchedAt = now ?? DateTime.now();
  }

  static void clear() {
    _wizard = null;
    _fetchedAt = null;
  }

  static DateTime? get fetchedAt => _fetchedAt;
}
