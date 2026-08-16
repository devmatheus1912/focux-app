import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../../onboarding/screens/setup_onboarding_widget.dart';
import '../../subscription/widgets/dashboard_activation_cta.dart';
import '../../subscription/widgets/plan_usage_banner.dart';
import '../../subscription/widgets/trial_countdown_banner.dart';
import '../data/command_center_data.dart';
import '../constants/dashboard_layout.dart';
import '../utils/dashboard_day_focus.dart';
import '../utils/dashboard_entry_motion.dart';
import '../utils/dashboard_home_focus.dart';
import '../utils/dashboard_home_snapshot.dart';
import '../utils/dashboard_scroll_logic.dart';
import '../utils/dashboard_screen_helpers.dart';
import 'dashboard_agenda_hoje_strip.dart';
import 'dashboard_attention_rail.dart';
import 'dashboard_base_radar_strip.dart';
import 'dashboard_command_center_section.dart';
import 'dashboard_day_focus_banner.dart';
import 'dashboard_home_coach_banner.dart';
import 'dashboard_home_header.dart';
import 'dashboard_pulse_strip.dart';

/// Slivers do fold principal: promo → header → foco → CC → agenda → atenção → pulso.
List<Widget> buildDashboardHomePrimarySlivers({
  required BuildContext context,
  required DashboardHomeSnapshot snap,
  required DashboardHomeFocusRules focusRules,
  required DashboardDayFocus dayFocus,
  required bool isDark,
  required Color primary,
  required String? nomePersonal,
  required String? logoUrl,
  required bool focusMode,
  required VoidCallback onToggleFocus,
  required String commandCenterSubtitle,
  required FinanceiroDashboard? finData,
  required List<CommandActionItem> nextActions,
  required List<CommandActionItem> prioritiesSheetActions,
  required bool showPrioritiesLink,
  required GlobalKey commandPanelKey,
  required int? mensagensNaoLidas,
  required Animation<double> commandFade,
  required Animation<double> kpiFade,
  required bool isCommandPreparing,
  required bool commandUnavailable,
  required int attentionSectionResetToken,
  required VoidCallback onReviewAttention,
  required bool onboardingIncomplete,
  required bool primeiroTreinoCriado,
  bool prioritiesChipVisible = false,
  String? pulseEmptyHint,
  int? notificacoesNaoLidasOverride,
  Color? brandAccent,
  VoidCallback? onQuickSearch,
  VoidCallback? onIaTeaser,
  VoidCallback? onHelp,
  List<AgendamentoResumo> agendaItems = const [],
  String? freshnessLabel,
  bool showCoachBanner = false,
  VoidCallback? onDismissCoach,
  List<AlunoScoreResumo> alunosScore = const [],
}) {
  final alunosAtivos = snap.alunosAtivos;
  final riscoAlto = snap.riscoAlto;
  final checkinsHoje = snap.checkinsHoje;
  final checkinsTrend = snap.checkinsTrend;
  final agendaHoje = snap.agendaHoje;
  final dismissCoach = onDismissCoach;

  return [
    if (!focusRules.hidePromoBanners) ...[
      const SliverToBoxAdapter(child: TrialCountdownBanner()),
      const SliverToBoxAdapter(child: PlanUsageBanner()),
      if (onboardingIncomplete)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              TokensStrip.s4,
              4,
              TokensStrip.s4,
              0,
            ),
            child: SetupOnboardingWidget(),
          ),
        )
      else
        SliverToBoxAdapter(
          child: DashboardActivationCta(
            alunosAtivos: alunosAtivos,
            temTreinos: primeiroTreinoCriado || checkinsHoje > 0,
            temFinanceiro:
                finData != null &&
                (finData.receitaMes > 0 ||
                    finData.vencimentosProximos.isNotEmpty),
          ),
        ),
    ],
    SliverToBoxAdapter(
      child: DashboardHomeHeader(
        nomePersonal: nomePersonal,
        logoUrl: logoUrl,
        isDark: isDark,
        primary: brandAccent ?? primary,
        onProfileTap: () => context.push('/perfil'),
        notificacoesCountOverride: notificacoesNaoLidasOverride,
        onQuickSearch: onQuickSearch,
        onIaTeaser: onIaTeaser,
        onHelp: onHelp,
        freshnessLabel: freshnessLabel,
      ),
    ),
    if (showCoachBanner && dismissCoach != null)
      SliverToBoxAdapter(
        child: DashboardHomeCoachBanner(
          isDark: isDark,
          onDismiss: dismissCoach,
        ),
      ),
    SliverToBoxAdapter(
      child: DashboardDayFocusBanner(
        focus: dayFocus,
        isDark: isDark,
        primary: primary,
        focusMode: focusMode,
        onToggleFocus: onToggleFocus,
      ),
    ),
    SliverToBoxAdapter(
      child: dashboardEntryMotion(
        context: context,
        fade: commandFade,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s4,
            0,
            TokensStrip.s4,
            TokensStrip.s4,
          ),
          child: DashboardCommandCenterSection(
            isDark: isDark,
            primary: primary,
            nextActions: nextActions,
            prioritiesSheetActions: prioritiesSheetActions,
            showPrioritiesLink: dashboardShowsInlinePrioritiesLink(
              showPrioritiesLink: showPrioritiesLink,
              stickyVisible: prioritiesChipVisible,
            ),
            panelKey: commandPanelKey,
            mensagensNaoLidas: mensagensNaoLidas,
            hideHeader: true,
            contextualSubtitle: commandCenterSubtitle,
            alunosAtivos: alunosAtivos,
            agendaHojeCount: agendaHoje,
            unreadCount: snap.unreadCount,
            isCommandPreparing: isCommandPreparing,
            commandUnavailable: commandUnavailable,
          ),
        ),
      ),
    ),
    if (agendaItems.isNotEmpty)
      SliverToBoxAdapter(
        child: DashboardAgendaHojeStrip(
          items: agendaItems,
          isDark: isDark,
          primary: primary,
        ),
      ),
    if (riscoAlto > 0 &&
        !snap.attentionVisible &&
        !focusRules.hideSecondaryRiskCtas)
      SliverToBoxAdapter(
        child: Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/retencao'),
            child: const Text('Ver saúde da base'),
          ),
        ),
      ),
    if (snap.attentionVisible) ...[
      SliverToBoxAdapter(
        child: DashboardAttentionRail(
          isDark: isDark,
          riskDominante: snap.riskDominante,
          riscoAlto: riscoAlto,
          alunosAtivos: alunosAtivos,
          dayFocusCoversRetention: focusRules.dayFocusCoversRetention,
          collapseAttention: focusRules.collapseAttention,
          attentionRiskItems: snap.attentionRiskItems,
          attentionVencItems: snap.attentionVencItems,
          attentionCollapsedPreview: snap.attentionCollapsedPreview,
          resetToken: attentionSectionResetToken,
          onReview: onReviewAttention,
        ),
      ),
      const SliverToBoxAdapter(
        child: SizedBox(height: DashboardLayout.sliverSectionGap),
      ),
    ],
    if (focusRules.omitSecondarySections && alunosScore.isNotEmpty)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s4),
          child: DashboardBaseRadarStrip(
            isDark: isDark,
            scores: alunosScore,
            initiallyExpanded: true,
          ),
        ),
      ),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s2,
          TokensStrip.s4,
          TokensStrip.s4,
        ),
        child: DashboardDayPulseStrip(
          fade: kpiFade,
          isDark: isDark,
          alunosAtivos: alunosAtivos,
          checkinsHoje: checkinsHoje,
          checkinsTrend: checkinsTrend,
          riscoAlto: riscoAlto,
          agendaHoje: agendaHoje,
          hideRiscoChip: snap.alunosEmRisco.isNotEmpty,
          primary: primary,
          collapseBody: focusRules.collapsePulseBody,
          trailingReserve: 0,
          emptyHint: dashboardPulseEmptyHint(
            checkinsHoje: checkinsHoje,
            checkinsTrend: checkinsTrend,
            fromApi: pulseEmptyHint,
          ),
          onAtivos:
              () => goPersonalShellTab(context, '/alunos?filtro=ativos'),
          onCheckins: () => goPersonalShellTab(context, '/checkin/historico'),
          onAgenda: () => goPersonalShellTab(context, '/agenda'),
          onRisco:
              riscoAlto > 0
                  ? () => goPersonalShellTab(context, '/alunos?filtro=risco')
                  : () => goPersonalShellTab(context, '/alunos'),
          hideEmptyTrend: focusRules.collapsePulseBody,
          showEmptyTrendCta:
              checkinsTrend.length >= 7 &&
              !checkinsTrend.any((v) => v > 0) &&
              alunosAtivos > 0 &&
              checkinsHoje == 0 &&
              !focusRules.suppressSecondaryEmptyCtas &&
              !focusRules.collapsePulseBody &&
              !focusRules.dayFocusCoversRetention,
          emptyTrendCtaLabel:
              primeiroTreinoCriado ? 'Ver agenda' : 'Agendar primeiro treino',
          onEmptyTrendCta:
              () =>
                  primeiroTreinoCriado
                      ? goPersonalShellTab(context, '/agenda')
                      : context.push('/treinos/novo'),
        ),
      ),
    ),
  ];
}
