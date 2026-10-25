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
import 'package:focux_app/features/ferramentas/data/ferramentas_catalogo_bootstrap.dart';
import 'package:focux_app/features/ferramentas/data/ferramentas_catalogo_models.dart';
import 'package:focux_app/features/ferramentas/providers/ferramentas_catalogo_provider.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/onboarding/data/onboarding_status_data.dart';
import 'package:focux_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/planos/providers/plano_features_provider.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/dynamic_type_harness.dart';
import '../../support/riverpod_seeds.dart';

DashboardHomeBundle _homeFixture({
  int totalAlunos = 4,
  List<AlertaResumo> risco = const [],
  List<MensalidadeResumo> cobrancas = const [],
  List<FilaAcaoResumo>? fila,
  List<AgendamentoResumo> agenda = const [],
  int mensagens = 1,
  int checkins = 2,
  double receita = 1200,
  int inadimplentes = 0,
}) {
  return DashboardHomeBundle(
    personal: DashboardData(
      totalAlunos: totalAlunos,
      alunosAtivos: totalAlunos,
      planoAtual: 'PRO',
      limiteAlunos: 50,
      nomePersonal: 'Matheus',
      corPrimaria: '#00D4E8',
    ),
    commandCenter: CommandCenterData(
      agendaHoje: agenda,
      alunosEmRisco: risco,
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
      cobrancasPendentes: cobrancas,
      autonomiaGargalos: const [],
      modoOperacao: const [],
      filaAcoes: fila ?? [
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

  for (final tela in kDynamicTypeTelas) {
    testWidgets('Hoje do Personal aguenta ${descreverTela(tela)}', (
      tester,
    ) async {
      usarDynamicTypeMaximo(tester, tela);
      await tester.binding.setSurfaceSize(tela);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pump(tester);
      expect(find.text('Agora'), findsOneWidget);
      expect(find.text('Ver o painel'), findsNothing);
      expect(tester.takeException(), isNull);

      final lista = find.byType(CustomScrollView).first;
      await tester.drag(lista, const Offset(0, -400));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'PersonalDashboardScreen monta fold com Semantics e ajuda',
    (tester) async {
      await _pump(tester);

      expect(find.byType(PersonalDashboardScreen), findsOneWidget);
      expect(find.textContaining('Matheus'), findsWidgets);
      expect(find.text('Agora'), findsOneWidget);
      expect(find.text('Ver o painel'), findsNothing);
      expect(find.text('Ferramentas'), findsOneWidget);

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

  group('Agora por pessoa', () {
    AlertaResumo risco(int id, String nome) => AlertaResumo(
      id: id,
      nomeAluno: nome,
      motivo: '9 dias sem treinar',
      nivelRisco: 'ALTO',
    );

    testWidgets('mostra 3 linhas com verbo e "Ver todas" abre o resto no lugar', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pump(
        tester,
        bundle: _homeFixture(
          risco: [risco(1, 'Hugo'), risco(2, 'Bia'), risco(3, 'Caio'), risco(4, 'Duda')],
          fila: const [],
          mensagens: 0,
        ),
      );

      expect(find.text('Chamar'), findsNWidgets(3));
      expect(find.text('Duda'), findsNothing);
      expect(find.text('Ver todas (4)'), findsOneWidget);

      await tester.tap(find.text('Ver todas (4)'));
      await tester.pump();
      expect(find.text('Chamar'), findsNWidgets(4));
      expect(find.text('Ver menos'), findsOneWidget);
    });

    testWidgets('cobrança só aparece vencida, com dias de atraso', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pump(
        tester,
        bundle: _homeFixture(
          fila: const [],
          mensagens: 0,
          cobrancas: [
            MensalidadeResumo(
              id: 1,
              nomeAluno: 'Ana',
              valor: 150,
              dataVencimento: '2026-10-01',
              diasAtraso: 3,
            ),
            MensalidadeResumo(
              id: 2,
              nomeAluno: 'Bruno',
              valor: 90,
              dataVencimento: '2026-11-01',
            ),
          ],
        ),
      );

      expect(find.text('Cobrar'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Bruno'), findsNothing);
    });

    testWidgets('dia quieto: "Tudo em dia" e convite, sem números zerados', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pump(
        tester,
        bundle: _homeFixture(fila: const [], mensagens: 0, receita: 0),
      );

      expect(find.text('Operação sob controle'), findsOneWidget);
      expect(find.text('Convidar um aluno'), findsOneWidget);
      expect(find.text('Dinheiro'), findsNothing);
    });

    testWidgets('mostra a base e o dinheiro quando há o que dizer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pump(
        tester,
        bundle: _homeFixture(risco: [risco(1, 'Hugo')], fila: const [], inadimplentes: 2),
      );

      expect(find.text('A base'), findsOneWidget);
      expect(find.text('Treinaram hoje'), findsOneWidget);
      expect(find.text('Em risco'), findsOneWidget);
      expect(find.text('Dinheiro'), findsOneWidget);
      expect(find.textContaining('2 em atraso'), findsOneWidget);
    });
  });
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

Future<void> _pump(WidgetTester tester, {DashboardHomeBundle? bundle}) async {
  final home = bundle ?? _homeFixture();
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
          (ref) async =>
              throw StateError('Home BFF already sent onboardingResumo'),
        ),
        seededPlanoFeatures(features),
        planosRepositoryProvider.overrideWithValue(_PlanosOffline()),
        ferramentasCatalogoProvider.overrideWith(_CatalogoLocal.new),
      ],
      child: MaterialApp.router(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}
