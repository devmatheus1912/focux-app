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

  static Future<OnboardingWizard>? _inflight;
  static int _generation = 0;

  /// Fresh cache, else one shared in-flight fetch for concurrent callers.
  static Future<OnboardingWizard> load(
    Future<OnboardingWizard> Function() fetch,
  ) {
    final fresh = getIfFresh();
    if (fresh != null) return Future.value(fresh);
    final existing = _inflight;
    if (existing != null) return existing;
    final gen = _generation;
    late final Future<OnboardingWizard> run;
    run = fetch()
        .then((w) {
          if (gen == _generation) put(w);
          return w;
        })
        .whenComplete(() {
          if (identical(_inflight, run)) _inflight = null;
        });
    return _inflight = run;
  }

  static void clear() {
    _wizard = null;
    _fetchedAt = null;
    _inflight = null;
    _generation++;
  }

  static DateTime? get fetchedAt => _fetchedAt;
}
