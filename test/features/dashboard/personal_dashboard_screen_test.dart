import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:focux_app/features/dashboard/screens/personal_dashboard_screen.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_day_focus.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_microcopy.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/onboarding/data/onboarding_status_data.dart';
import 'package:focux_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/riverpod_seeds.dart';

DashboardHomeBundle _homeFixture() {
  return DashboardHomeBundle(
    personal: DashboardData(
      totalAlunos: 4,
      alunosAtivos: 4,
      planoAtual: 'PRO',
      limiteAlunos: 50,
      nomePersonal: 'Matheus',
      corPrimaria: '#00D4E8',
    ),
    commandCenter: CommandCenterData(
      agendaHoje: const [],
      alunosEmRisco: const [],
      alunosScore: [
        AlunoScoreResumo(
          alunoId: 1,
          alunoNome: 'Ana',
          score: 72,
          ritmo: 'Ritmo construindo',
          risco: 'Risco baixo',
          proximaAcao: 'Pedir feedback',
          narrativa: '',
          objetivo: 'Força',
          acaoUrl: '/alunos/1',
          prioridade: 'P1',
          iaSugerida: false,
        ),
      ],
      cobrancasPendentes: const [],
      autonomiaGargalos: const [],
      modoOperacao: const [],
      filaAcoes: [
        FilaAcaoResumo(
          tipo: 'AGENDA',
          actionKey: 'AGENDA_TODAY',
          titulo: 'Revisar agenda',
          descricao: '2 compromissos',
          acaoUrl: '/agenda',
          prioridade: 'P1',
          severidade: 'MEDIA',
          responsavel: 'Personal',
          sla: 'Hoje',
          status: 'ABERTO',
          ctaLabel: 'Abrir',
          iaSugerida: false,
        ),
      ],
    ),
    financeiro: FinanceiroDashboard(
      receitaMes: 1200,
      receitaAcumulada: 1200,
      ticketMedio: 300,
      totalInadimplentes: 0,
      previsaoReceita: 2000,
      vencimentosProximos: const [],
      topAlunos: const [],
      evolucaoMensal: const [],
    ),
    pulse: const DashboardPulseSnapshot(
      checkinsHoje: 2,
      mensagensNaoLidas: 1,
      checkinsTrend: [0, 1, 0, 2, 1, 0, 2],
    ),
    notificacoesNaoLidas: 2,
    onboardingResumo: OnboardingStatusData(
      perfilCompleto: true,
      primeiroAlunoAdicionado: true,
      primeiroTreinoCriado: true,
      pagamentoConfigurado: true,
      pacoteCriado: true,
      habitoConfigurado: true,
      linkBioConfigurado: true,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'focux_home_focus_mode_v1': false,
      'focux_home_coach_v1': true,
    });
    DashboardHomeClientCache.clear();
  });

  testWidgets(
    'PersonalDashboardScreen monta fold com Semantics e ajuda',
    (tester) async {
      final home = _homeFixture();
      const features = PlanoFeatures(
        plano: SubscriptionPlan.PRO,
        financeiro: true,
        agenda: true,
        relatorios: true,
        whiteLabel: false,
        iaCopiloto: true,
        migracaoFoto: false,
      );

      final router = GoRouter(
        initialLocation: '/dashboard/personal',
        routes: [
          GoRoute(
            path: '/dashboard/personal',
            builder: (context, state) => const PersonalDashboardScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardHomeProvider.overrideWith((ref) async => home),
            onboardingStatusProvider.overrideWith(
              (ref) async => throw StateError(
                'Home BFF already sent onboardingResumo',
              ),
            ),
            seededPlanoFeatures(features),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(PersonalDashboardScreen), findsOneWidget);
      expect(find.textContaining('Matheus'), findsWidgets);
      expect(find.text('Foco do dia'), findsOneWidget);

      final focusSemantics = tester.getSemantics(find.text('Foco do dia'));
      expect(
        focusSemantics.label,
        anyOf(
          contains('Foco do dia'),
          contains('operação sob controle'),
          contains('Operação sob controle'),
        ),
      );

      final help = find.byTooltip(DashboardMicrocopy.helpHomeOpen);
      expect(help, findsOneWidget);
      await tester.ensureVisible(help);
      await tester.tap(help);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(DashboardMicrocopy.helpHomeTitle), findsOneWidget);
      expect(find.text('Índice Focux'), findsOneWidget);
    },
  );
}
