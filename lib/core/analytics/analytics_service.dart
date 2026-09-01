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
      await FirebaseCrashlytics.instance.log(
        'event=$event '
        '${props == null ? '' : props.entries.map((e) => '${e.key}=${e.value}').join(' ')}',
      );
    } catch (_) {}
  }

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: reason,
      );
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
  static const featureEducationOpened = 'feature_education_opened';
  static const roiCalculatorUsed = 'roi_calculator_used';
  static const billingToggleChanged = 'billing_toggle_changed';
  static const checkoutStarted = 'checkout_started';
  static const checkoutCompleted = 'checkout_completed';
  static const checkoutFailed = 'checkout_failed';
  static const subscriptionStarted = 'subscription_started';
  static const subscriptionCancelled = 'subscription_cancelled';
  static const trialStarted = 'trial_started';

  static const alunoCreated = 'aluno_created';
  static const treinoCreated = 'treino_created';

  static const iaInsightRequested = 'ia_insight_requested';
  static const iaQuotaExhausted = 'ia_quota_exhausted';
  static const iaCopilotFailure = 'ia_copilot_failure';
  static const iaCopilotoViewed = 'ia_copiloto_viewed';
  static const iaCopilotoTtv = 'ia_copiloto_ttv';
  static const iaCopilotoHelpOpened = 'ia_copiloto_help_opened';
  static const iaCopilotoModeChanged = 'ia_copiloto_mode_changed';

  static const referralLinkShared = 'referral_link_shared';
  static const activationCtaTapped = 'activation_cta_tapped';
  static const setupWizardViewed = 'setup_wizard_viewed';
  static const setupWizardRefreshed = 'setup_wizard_refreshed';
  static const setupWizardContinue = 'setup_wizard_continue';
  static const setupWizardCompleted = 'setup_wizard_completed';
  static const setupWizardTtv = 'setup_wizard_ttv';
  static const mensalidadeCreated = 'mensalidade_created';
  static const paywallDismissed = 'paywall_dismissed';
  static const trialBannerTapped = 'trial_banner_tapped';

  static const featureGateBlocked = 'feature_gate_blocked';
  static const planGateStaleUsed = 'plan_gate_stale_used';
  static const planGateRefreshFailed = 'plan_gate_refresh_failed';

  static const cancelSaveOpened = 'cancel_save_opened';
  static const cancelSaveMotivoSelected = 'cancel_save_motivo_selected';
  static const cancelSaveOfertaLoaded = 'cancel_save_oferta_loaded';
  static const cancelSaveOfertaAccepted = 'cancel_save_oferta_accepted';
  static const cancelSaveOfertaDeclined = 'cancel_save_oferta_declined';

  static const alunoAutonomyTaskViewed = 'aluno_autonomy_task_viewed';
  static const alunoAutonomyTaskClicked = 'aluno_autonomy_task_clicked';
  static const alunoAutonomyTaskCompleted = 'aluno_autonomy_task_completed';

  static const aluno360CopilotRefresh = 'aluno360_copilot_refresh';
  static const aluno360CopilotExecutarAcao = 'aluno360_copilot_executar_acao';
  static const aluno360OutreachPrepared = 'aluno360_outreach_prepared';
  static const aluno360OutreachChatOpened = 'aluno360_outreach_chat_opened';
  static const aluno360HelpOpened = 'aluno360_help_opened';

  static const homeViewed = 'home_viewed';
  static const homeRefreshed = 'home_refreshed';
  static const homeFocusToggled = 'home_focus_toggled';
  static const homeRadarTap = 'home_radar_tap';
  static const homeCatalogOpened = 'home_catalog_opened';
  static const homeCoachDismissed = 'home_coach_dismissed';
  static const homeTtv = 'home_ttv';
  static const homeSearchOpened = 'home_search_opened';
  static const homePrioritiesOpened = 'home_priorities_opened';
  static const homeDayFocusAction = 'home_day_focus_action';
  static const homeHelpOpened = 'home_help_opened';

  static const alunosAddTapped = 'alunos_add_tapped';
  static const alunosViewed = 'alunos_viewed';
  static const alunosFilterChanged = 'alunos_filter_changed';
  static const alunosSearchUsed = 'alunos_search_used';
  static const alunosHelpOpened = 'alunos_help_opened';
  static const alunosRefreshed = 'alunos_refreshed';
  static const alunosOrganizeOpened = 'alunos_organize_opened';
  static const alunosBulkOpened = 'alunos_bulk_opened';
  static const treinosViewed = 'treinos_viewed';
  static const treinosTtv = 'treinos_ttv';
  static const treinosRefreshed = 'treinos_refreshed';
  static const treinosSearchUsed = 'treinos_search_used';
  static const treinosHelpOpened = 'treinos_help_opened';
  static const treinosCreateTapped = 'treinos_create_tapped';
  static const treinosActionOpened = 'treinos_action_opened';
  static const treinosAssigned = 'treinos_assigned';
  static const treinosCloned = 'treinos_cloned';
  static const treinosDuplicated = 'treinos_duplicated';
  static const treinosBulkOpened = 'treinos_bulk_opened';
  static const treinosDeleted = 'treinos_deleted';
  static const treinoDetailViewed = 'treino_detail_viewed';
  static const treinoDetailAddTapped = 'treino_detail_add_tapped';
  static const treinoDetailMenuOpened = 'treino_detail_menu_opened';
  static const treinoExerciseMenuOpened = 'treino_exercise_menu_opened';
  static const treinoDetailHelpOpened = 'treino_detail_help_opened';
  static const treinoDetailRefreshed = 'treino_detail_refreshed';
  static const treinoPrescriptionSaved = 'treino_prescription_saved';
  static const leadCreatedOrOpened = 'lead_created_or_opened';
  static const alertaRiscoOpened = 'alerta_risco_opened';
  static const alertasHubViewed = 'alertas_hub_viewed';
  static const alertasHubTtv = 'alertas_hub_ttv';
  static const alertasHubHelpOpened = 'alertas_hub_help_opened';
  static const alertasHubRefreshed = 'alertas_hub_refreshed';
  static const alertasDetalheViewed = 'alertas_detalhe_viewed';
  static const alertasDetalheTtv = 'alertas_detalhe_ttv';
  static const alertasDetalheHelpOpened = 'alertas_detalhe_help_opened';
  static const alertasDetalheRefreshed = 'alertas_detalhe_refreshed';
  static const dunningMarkedRecovered = 'dunning_marked_recovered';
  static const automacaoTemplateActivated = 'automacao_template_activated';
  static const lojaCheckoutStarted = 'loja_checkout_started';
  static const habitoCreated = 'habito_created';
  static const checkinHubViewed = 'checkin_hub_viewed';
  static const checkinHubTtv = 'checkin_hub_ttv';
  static const checkinHubHelpOpened = 'checkin_hub_help_opened';
  static const checkinHubRefreshed = 'checkin_hub_refreshed';
  static const notificacoesViewed = 'notificacoes_viewed';
  static const notificacoesTtv = 'notificacoes_ttv';
  static const notificacoesHelpOpened = 'notificacoes_help_opened';
  static const notificacoesRefreshed = 'notificacoes_refreshed';
  static const notificacoesMarkedAllRead = 'notificacoes_marked_all_read';
  static const notificacoesOpened = 'notificacoes_opened';
  static const chatInboxViewed = 'chat_inbox_viewed';
  static const chatInboxTtv = 'chat_inbox_ttv';
  static const chatInboxHelpOpened = 'chat_inbox_help_opened';
  static const chatInboxRefreshed = 'chat_inbox_refreshed';
  static const chatThreadOpened = 'chat_thread_opened';
  static const financeiroViewed = 'financeiro_viewed';
  static const financeiroTtv = 'financeiro_ttv';
  static const financeiroHelpOpened = 'financeiro_help_opened';
  static const financeiroRefreshed = 'financeiro_refreshed';
  static const financeiroMensalidadesOpened = 'financeiro_mensalidades_opened';
  static const financeiroCobrarViaChat = 'financeiro_cobrar_via_chat';

  static const agendaViewed = 'agenda_viewed';
  static const agendaRefreshed = 'agenda_refreshed';
  static const agendaHelpOpened = 'agenda_help_opened';
  static const agendaCreated = 'agenda_created';
  static const agendaStatusChanged = 'agenda_status_changed';
  static const agendaDeleted = 'agenda_deleted';
  static const agendaWhatsapp = 'agenda_whatsapp';
  static const agendaAlunoOpened = 'agenda_aluno_opened';
  static const agendaRescheduled = 'agenda_rescheduled';

  static const perfilViewed = 'perfil_viewed';
  static const perfilRefreshed = 'perfil_refreshed';
  static const perfilUpdated = 'perfil_updated';
  static const perfilStickyTapped = 'perfil_sticky_tapped';
  static const perfilShareTapped = 'perfil_share_tapped';
  static const perfilMarcaHintOpened = 'perfil_marca_hint_opened';
}
