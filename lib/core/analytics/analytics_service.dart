import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Camada única de analytics + crash reporting do app.
///
/// O objetivo é evitar callsites espalhados de `FirebaseCrashlytics` /
/// `FirebaseAnalytics`. Aqui consolidamos:
///
/// - eventos de produto críticos (CTA, conversão, churn) para retenção.
/// - breadcrumbs do Crashlytics para correlacionar exceções com a jornada.
/// - logging condicionado a debug: nada vai pra prod sem motivo.
///
/// Implementação atual: Crashlytics breadcrumbs + debug log. Trocar para
/// Sentry/Amplitude/PostHog é uma implementação por método sem mexer
/// nos callsites.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  bool _userIdSet = false;

  Future<void> setUser({required String id, String? role, String? plan}) async {
    if (_userIdSet) return;
    _userIdSet = true;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(id);
      if (role != null) {
        await FirebaseCrashlytics.instance.setCustomKey('role', role);
      }
      if (plan != null) {
        await FirebaseCrashlytics.instance.setCustomKey('plan', plan);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Analytics] setUser failed: $e');
    }
  }

  /// Evento de produto: CTA, conversão, churn, etc. Mantenha nomes em
  /// snake_case e estáveis (são chave de funil).
  Future<void> track(String event, {Map<String, Object?>? props}) async {
    final payload = <String, Object?>{'event': event, ...?props};
    if (kDebugMode) debugPrint('[Analytics] $payload');
    try {
      await FirebaseCrashlytics.instance.log('event=$event '
          '${props == null ? '' : props.entries.map((e) => '${e.key}=${e.value}').join(' ')}');
    } catch (_) {}
  }

  Future<void> recordError(Object error, StackTrace? stack, {String? reason}) async {
    try {
      await FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
    } catch (e) {
      if (kDebugMode) debugPrint('[Analytics] recordError failed: $e');
    }
  }
}

/// Eventos canônicos de produto. Mantenha esta enumeração como
/// fonte da verdade dos nomes de evento — qualquer adição/remoção
/// passa por code review por mexer em métricas de retenção/churn.
class ProductEvents {
  ProductEvents._();

  static const loginSuccess = 'login_success';
  static const loginFailure = 'login_failure';

  static const paywallOpened = 'paywall_opened';
  static const paywallPlanSelected = 'paywall_plan_selected';
  static const paywallCtaTapped = 'paywall_cta_tapped';
  static const subscriptionStarted = 'subscription_started';
  static const subscriptionCancelled = 'subscription_cancelled';
  static const trialStarted = 'trial_started';

  static const alunoCreated = 'aluno_created';
  static const treinoCreated = 'treino_created';

  static const iaInsightRequested = 'ia_insight_requested';
  static const iaQuotaExhausted = 'ia_quota_exhausted';
  static const iaCopilotFailure = 'ia_copilot_failure';

  static const featureGateBlocked = 'feature_gate_blocked';
  static const planGateStaleUsed = 'plan_gate_stale_used';
  static const planGateRefreshFailed = 'plan_gate_refresh_failed';

  static const alunoAutonomyTaskViewed = 'aluno_autonomy_task_viewed';
  static const alunoAutonomyTaskClicked = 'aluno_autonomy_task_clicked';
  static const alunoAutonomyTaskCompleted = 'aluno_autonomy_task_completed';
}
