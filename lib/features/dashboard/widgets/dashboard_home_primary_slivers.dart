import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../../onboarding/data/onboarding_status_data.dart';
import '../../onboarding/screens/setup_onboarding_widget.dart';
import '../../subscription/widgets/dashboard_activation_cta.dart';
import '../../subscription/widgets/plan_usage_banner.dart';
import '../../subscription/widgets/trial_countdown_banner.dart';
import '../data/command_action_item.dart';
import '../data/command_center_data.dart';
import '../constants/dashboard_layout.dart';
import '../utils/dashboard_day_focus.dart';
import '../utils/dashboard_home_focus.dart';
import '../utils/dashboard_home_snapshot.dart';
import '../utils/dashboard_screen_helpers.dart';
import '../utils/hoje_personal_card.dart';
import '../utils/hoje_personal_dia.dart';
import 'dashboard_home_header.dart';
import 'dashboard_pulse_strip.dart';
import 'hoje_personal_card_view.dart';

/// Primeira tela: cabeçalho, um card e o texto que abre o painel.
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
  required bool onboardingIncomplete,
  required bool primeiroTreinoCriado,
  OnboardingStatusData? onboardingFromHome,
  bool prioritiesChipVisible = false,
  String? pulseEmptyHint,
  int? notificacoesNaoLidasOverride,
  Color? brandAccent,
  VoidCallback? onQuickSearch,
  VoidCallback? onHelp,
  List<AgendamentoResumo> agendaItems = const [],
  String? freshnessLabel,
  bool showCoachBanner = false,
  VoidCallback? onDismissCoach,
  List<AlunoScoreResumo> alunosScore = const [],
  int coachPending = 0,
  String? coachPendingLabel,
  required HojePersonalCard card,
  required VoidCallback onCard,
  List<Widget> painelExtra = const [],
}) {
  final alunosAtivos = snap.alunosAtivos;
  final riscoAlto = snap.riscoAlto;
  final checkinsHoje = snap.checkinsHoje;
  final checkinsTrend = snap.checkinsTrend;
  final agendaHoje = snap.agendaHoje;

  final header = DashboardHomeHeader(
    nomePersonal: nomePersonal,
    logoUrl: logoUrl,
    isDark: isDark,
    primary: brandAccent ?? primary,
    onProfileTap: () => context.push('/perfil'),
    notificacoesCountOverride: notificacoesNaoLidasOverride,
    onQuickSearch: onQuickSearch,
    onHelp: onHelp,
    freshnessLabel: freshnessLabel,
  );

  final painel = <Widget>[
    if (!focusRules.hidePromoBanners) ...[
      const TrialCountdownBanner(),
      const PlanUsageBanner(),
    ],
    if (!focusRules.hidePromoBanners)
      onboardingIncomplete
          ? SetupOnboardingWidget(statusFromHome: onboardingFromHome)
          : DashboardActivationCta(
            alunosAtivos: alunosAtivos,
            temTreinos: primeiroTreinoCriado || checkinsHoje > 0,
            temFinanceiro:
                finData != null &&
                (finData.receitaMes.isPositive ||
                    finData.vencimentosProximos.isNotEmpty),
          ),
    Padding(
      padding: DashboardLayout.foldCard,
      child: DashboardDayPulseStrip(
        fade: kpiFade,
        isDark: isDark,
        alunosAtivos: alunosAtivos,
        checkinsHoje: checkinsHoje,
        checkinsTrend: checkinsTrend,
        riscoAlto: riscoAlto,
        primary: primary,
        collapseBody: focusRules.collapsePulseBody,
        trailingReserve: 0,
        emptyHint: dashboardPulseEmptyHint(
          checkinsHoje: checkinsHoje,
          checkinsTrend: checkinsTrend,
          fromApi: pulseEmptyHint,
        ),
        onAtivos: () => goPersonalShellTab(context, '/alunos?filtro=ativos'),
        onCheckins: () => context.push('/checkin'),
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
    ...painelExtra,
  ];

  return [
    SliverToBoxAdapter(child: header),
    SliverToBoxAdapter(
      child: HojePersonalCardView(
        card: card,
        linhas: hojePersonalDia(
          agendaHoje: agendaHoje,
          alunosContato: riscoAlto,
          mensalidades: snap.cobrancasPendentes,
          conversas: snap.unreadCount,
          alunosNaBase: alunosAtivos,
        ),
        onLinha: (linha) => openPersonalRoute(context, linha.rota),
        onAction: onCard,
        onVerPainel: () => showHojePersonalPainel(context, children: painel),
      ),
    ),
  ];
}
