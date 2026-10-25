import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:focux_app/features/dashboard/screens/personal_dashboard_screen.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_day_focus.dart';
import 'package:focux_app/features/ferramentas/data/ferramentas_catalogo_bootstrap.dart';
import 'package:focux_app/features/ferramentas/data/ferramentas_catalogo_models.dart';
import 'package:focux_app/features/ferramentas/providers/ferramentas_catalogo_provider.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/onboarding/data/onboarding_repository.dart';
import 'package:focux_app/features/onboarding/data/onboarding_status_data.dart';
import 'package:focux_app/features/onboarding/data/onboarding_wizard_client_cache.dart';
import 'package:focux_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/planos/providers/plano_features_provider.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'riverpod_seeds.dart';

/// Home do personal para os goldens: o mínimo que a Hoje precisa.
DashboardHomeBundle hojeBundle({
  int totalAlunos = 6,
  List<AlertaResumo> risco = const [],
  List<MensalidadeResumo> cobrancas = const [],
  List<FilaAcaoResumo> fila = const [],
  List<AgendamentoResumo> agenda = const [],
  int mensagens = 0,
  int checkins = 0,
  double receita = 0,
  int inadimplentes = 0,
  bool onboardingCompleto = true,
}) {
  return DashboardHomeBundle(
    personal: DashboardData(
      totalAlunos: totalAlunos,
      alunosAtivos: totalAlunos,
      planoAtual: 'PRO',
      limiteAlunos: 50,
      nomePersonal: 'Matheus',
      corPrimaria: '#0B4F5C',
    ),
    commandCenter: CommandCenterData(
      agendaHoje: agenda,
      alunosEmRisco: risco,
      alunosScore: const [],
      cobrancasPendentes: cobrancas,
      autonomiaGargalos: const [],
      modoOperacao: const [],
      filaAcoes: fila,
    ),
    financeiro: FinanceiroDashboard(
      receitaMes: receita,
      receitaAcumulada: receita,
      ticketMedio: 300,
      totalInadimplentes: inadimplentes,
      previsaoReceita: 2000,
      vencimentosProximos: const [],
      topAlunos: const [],
      evolucaoMensal: const [],
    ),
    pulse: DashboardPulseSnapshot(
      checkinsHoje: checkins,
      mensagensNaoLidas: mensagens,
      checkinsTrend: const [0, 1, 0, 2, 1, 0, 2],
    ),
    notificacoesNaoLidas: 2,
    onboardingResumo: OnboardingStatusData(
      perfilCompleto: onboardingCompleto,
      primeiroAlunoAdicionado: onboardingCompleto,
      primeiroTreinoCriado: onboardingCompleto,
      pagamentoConfigurado: onboardingCompleto,
      pacoteCriado: onboardingCompleto,
      habitoConfigurado: onboardingCompleto,
      linkBioConfigurado: onboardingCompleto,
    ),
    dayFocus: const DashboardDayFocus(
      kind: DashboardDayFocusKind.estavel,
      headline: 'Operação sob controle',
      detail: 'Use as próximas ações.',
      semanticLabel: 'Foco do dia: operação sob controle.',
      coversRetention: false,
      riskDominante: false,
    ),
  );
}

class _PlanosOffline implements PlanosRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Never>.error(StateError('offline'));
}

class _CatalogoLocal extends FerramentasCatalogoNotifier {
  @override
  Future<FerramentasCatalogo> build() async => ferramentasCatalogoBootstrap();
}

/// Sobe a Hoje com [bundle]. O brilho vem de [escuro].
Widget hojeApp(DashboardHomeBundle bundle, {required bool escuro}) {
  // O wizard já veio da Home: a tela não sai à rede para decidir se abre o wizard.
  OnboardingWizardClientCache.put(
    OnboardingWizard(
      steps: const [],
      completedCount: 7,
      totalCount: 7,
      progressPercent: 100,
      nextActionLabel: '',
      nextActionRoute: '',
      wizardCompleto: true,
      allStepsDone: true,
    ),
  );
  const features = PlanoFeatures(
    plano: SubscriptionPlan.PRO,
    financeiro: true,
    agenda: true,
    relatorios: true,
    whiteLabel: false,
    iaCopiloto: true,
    migracaoFoto: false,
  );
  final brilho = escuro ? Brightness.dark : Brightness.light;
  final router = GoRouter(
    initialLocation: '/dashboard/personal',
    routes: [
      GoRoute(
        path: '/dashboard/personal',
        builder: (context, state) => const PersonalDashboardScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      dashboardHomeProvider.overrideWith((ref) async => bundle),
      onboardingStatusProvider.overrideWith(
        (ref) async => throw StateError('Home BFF already sent onboardingResumo'),
      ),
      seededPlanoFeatures(features),
      planosRepositoryProvider.overrideWithValue(_PlanosOffline()),
      ferramentasCatalogoProvider.overrideWith(_CatalogoLocal.new),
    ],
    child: RepaintBoundary(
      key: const ValueKey('tela'),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: brilho,
          colorScheme: ColorScheme.fromSeed(
            seedColor: EagleTokens.brandAccent,
            brightness: brilho,
          ),
          useMaterial3: true,
        ),
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
}

Future<void> assentarHoje(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}
