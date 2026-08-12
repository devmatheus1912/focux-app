import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../../onboarding/screens/setup_onboarding_widget.dart';
import '../../subscription/widgets/dashboard_activation_cta.dart';
import '../../subscription/widgets/plan_usage_banner.dart';
import '../../subscription/widgets/trial_countdown_banner.dart';
import '../constants/dashboard_layout.dart';
import '../utils/dashboard_day_focus.dart';
import '../utils/dashboard_entry_motion.dart';
import '../utils/dashboard_home_focus.dart';
import '../utils/dashboard_home_snapshot.dart';
import 'dashboard_attention_rail.dart';
import 'dashboard_command_center_section.dart';
import 'dashboard_command_center_sticky_header.dart';
import 'dashboard_day_focus_banner.dart';
import 'dashboard_home_header.dart';
import 'dashboard_pulse_strip.dart';

/// Slivers do fold principal: promo → header → foco → CC → atenção → pulso.
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
  required bool showStickyPrioritiesAction,
  required String? stickyCommandActionsLabel,
  required VoidCallback? onTrailingAction,
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
}) {
  final alunosAtivos = snap.alunosAtivos;
  final riscoAlto = snap.riscoAlto;
  final checkinsHoje = snap.checkinsHoje;
  final checkinsTrend = snap.checkinsTrend;
  final agendaHoje = snap.agendaHoje;

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
        primary: primary,
        onProfileTap: () => context.push('/perfil'),
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
    SliverPersistentHeader(
      pinned: true,
      delegate: DashboardCommandCenterStickyHeaderDelegate(
        isDark: isDark,
        primary: primary,
        subtitle: commandCenterSubtitle,
        compact: focusRules.compactCommandSticky,
        showPrioritiesAction: showStickyPrioritiesAction,
        trailingActionLabel: stickyCommandActionsLabel,
        onTrailingAction: onTrailingAction,
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
            finData: finData,
            nextActions: nextActions,
            prioritiesSheetActions: prioritiesSheetActions,
            showPrioritiesLink: showPrioritiesLink,
            panelKey: commandPanelKey,
            mensagensNaoLidas: mensagensNaoLidas,
            hideHeader: true,
            contextualSubtitle: commandCenterSubtitle,
            collapseQuickLinks: focusRules.collapseQuickLinks,
            alunosAtivos: alunosAtivos,
            agendaHojeCount: agendaHoje,
            unreadCount: snap.unreadCount,
            copilotOpenCount:
                snap.filaAcoes.where((a) => a.tipo == 'IA_COPILOTO').length,
            isCommandPreparing: isCommandPreparing,
            commandUnavailable: commandUnavailable,
          ),
        ),
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
          onAtivos:
              () => goPersonalShellTab(context, '/alunos?filtro=ativos'),
          onCheckins: () => context.go('/checkin/historico'),
          onAgenda: () => goPersonalShellTab(context, '/agenda'),
          onRisco:
              riscoAlto > 0
                  ? () => goPersonalShellTab(context, '/alunos?filtro=risco')
                  : () => goPersonalShellTab(context, '/alunos'),
          showEmptyTrendCta:
              checkinsTrend.length >= 7 &&
              !checkinsTrend.any((v) => v > 0) &&
              alunosAtivos > 0 &&
              checkinsHoje == 0 &&
              !focusRules.suppressSecondaryEmptyCtas &&
              !focusRules.collapsePulseBody,
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
