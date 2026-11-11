import '../../../core/widgets/fx_action_link.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/theme/fx_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/fx_money.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../../onboarding/data/onboarding_status_data.dart';
import '../../onboarding/data/setup_steps_catalog.dart';
import '../../onboarding/screens/setup_onboarding_widget.dart';
import '../../subscription/widgets/dashboard_activation_cta.dart';
import '../../subscription/widgets/plan_usage_banner.dart';
import '../../subscription/widgets/trial_countdown_banner.dart';
import '../data/command_center_data.dart';
import '../utils/dashboard_home_snapshot.dart';
import '../utils/hoje_agora.dart';
import 'dashboard_agenda_hoje_strip.dart';
import 'dashboard_home_header.dart';
import 'hoje_agora_secao.dart';
import 'hoje_base_secao.dart';

/// A Hoje do personal numa tela só: cabeçalho, aviso do plano, "Agora",
/// agenda, a base, o dinheiro e a porta das ferramentas.
/// Quem decide o que entra em "Agora" é [hojeAgora]; zero não aparece.
List<Widget> buildDashboardHomePrimarySlivers({
  required BuildContext context,
  required DashboardHomeSnapshot snap,
  required bool isDark,
  required Color primary,
  required String? nomePersonal,
  required String? logoUrl,
  required CommandCenterData commandCenter,
  required FinanceiroDashboard? finData,
  required bool temAluno,
  required bool onboardingIncomplete,
  required bool primeiroTreinoCriado,
  OnboardingStatusData? onboardingFromHome,
  SetupStepCatalogEntry? proximoPasso,
  int? notificacoesNaoLidasOverride,
  Color? brandAccent,
  VoidCallback? onQuickSearch,
  VoidCallback? onHelp,
  String? freshnessLabel,
}) {
  final header = DashboardHomeHeader(
    nomePersonal: nomePersonal,
    logoUrl: logoUrl,
    isDark: isDark,
    primary: brandAccent ?? primary,
    onProfileTap: () => context.push('/perfil'),
    notificacoesCountOverride: notificacoesNaoLidasOverride,
    onQuickSearch: onQuickSearch,
    freshnessLabel: hojeLinhaUtil(
      atendimentos: commandCenter.agendaHojeCount,
      freshness: freshnessLabel,
    ),
    onCopiloto: () => context.push('/ia/copiloto'),
  );

  final itens = hojeAgora(
    risco: commandCenter.alunosEmRisco,
    cobrancas: commandCenter.cobrancasPendentes,
    fila: commandCenter.filaAcoes,
    conversasSemResposta: snap.unreadCount,
  );
  final fichas = commandCenter.filaAcoes
      .where((a) => a.actionKey.startsWith('FICHA_VENCENDO_'))
      .toList(growable: false);
  final semAlunoComPasso = !temAluno && proximoPasso != null;

  return [
    SliverToBoxAdapter(child: header),
    const SliverToBoxAdapter(child: TrialCountdownBanner()),
    const SliverToBoxAdapter(child: PlanUsageBanner()),
    if (semAlunoComPasso)
      SliverToBoxAdapter(child: HojeProximoPasso(passo: proximoPasso))
    else
      SliverToBoxAdapter(child: HojeAgoraSecao(itens: itens, temAluno: temAluno)),
    if (temAluno)
      SliverToBoxAdapter(
        child: onboardingIncomplete
            ? SetupOnboardingWidget(statusFromHome: onboardingFromHome)
            : DashboardActivationCta(
                alunosAtivos: snap.alunosAtivos,
                temTreinos: primeiroTreinoCriado || snap.checkinsHoje > 0,
                temFinanceiro:
                    finData != null &&
                    (finData.receitaMes.isPositive ||
                        finData.vencimentosProximos.isNotEmpty),
              ),
      ),
    SliverToBoxAdapter(
      child: DashboardAgendaHojeStrip(items: commandCenter.agendaHoje),
    ),
    if (snap.alunosAtivos > 0)
      SliverToBoxAdapter(
        child: HojeBaseSecao(
          treinaramHoje: snap.checkinsHoje,
          emRisco: snap.riscoAlto,
          fichasAVencer: fichasAVencer(commandCenter.filaAcoes),
          rotaDasFichas: fichas.length == 1 && fichas.first.acaoUrl.startsWith('/')
              ? fichas.first.acaoUrl
              : '/alunos',
        ),
      ),
    SliverToBoxAdapter(
      child: HojeDinheiroLinha(
        mes: snap.mesLabel,
        recebido: finData?.receitaMes ?? FxMoney.zero,
        emAtraso: finData?.totalInadimplentes ?? 0,
      ),
    ),
    const SliverToBoxAdapter(child: HojeFerramentasLinha()),
    // A ajuda saiu do topo (três botões cabem com o nome em 22).
    if (onHelp != null)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FxSettingsLayout.pageInset,
            TokensStrip.s2,
            FxSettingsLayout.pageInset,
            TokensStrip.s4,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FxActionLink(
              label: 'Como usar a Hoje',
              icon: FxIcons.ajuda,
              onTap: onHelp,
            ),
          ),
        ),
      ),
  ];
}
