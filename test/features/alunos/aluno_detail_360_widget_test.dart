import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/operational_metric_tile.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/ia/models/ia_copilot_proxima_acao.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/providers/alunos_provider.dart';
import 'package:focux_app/features/alunos/screens/aluno_detail_screen.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/planos/providers/plano_features_provider.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _proPlanoFeatures = PlanoFeatures(
  plano: SubscriptionPlan.PRO,
  financeiro: true,
  agenda: true,
  relatorios: true,
  whiteLabel: false,
  iaCopiloto: true,
  migracaoFoto: false,
);

Override _proPlanoFeaturesOverride() {
  return planoFeaturesProvider.overrideWith((ref) {
    final notifier = PlanoFeaturesNotifier(
      PlanosRepository(ref.read(apiClientProvider)),
    );
    notifier.seedFromHome(_proPlanoFeatures);
    return notifier;
  });
}

const _alunoId = 42;
const _contactPriorityAlunoId = 7;

final _emptyEvolucaoFixture = EvolucaoInteligente(
  sinal: 'SEM_DADOS',
  resumo: '',
  volumeSemanal: 0,
  volumeMensal: 0,
  proximaAcao: '',
  sugerirCopiloto: false,
);

final _beatrizFixture = Aluno(
  id: _contactPriorityAlunoId,
  nome: 'Beatriz',
  email: 'beatriz@test.com',
  status: 'ATIVO',
  emRisco: true,
  riscoNivel: 'ALTO',
  aderenciaPercent: 0,
  diasSemTreino: 14,
  objetivo: 'Hipertrofia',
);

final _beatriz360Fixture = Aluno360(
  aluno: _beatrizFixture,
  autonomiaResumo: AlunoAutonomiaResumo(
    alunoId: _contactPriorityAlunoId,
    totalEventos: 0,
    vistos: 0,
    cliques: 0,
    concluidos: 0,
  ),
  timelinePreview: const [],
  proximaAcao: ProximaAcaoResumo(
    acao: 'Retomar contato com Beatriz',
    motivo: 'Sem check-ins recentes',
    fonte: 'PADRAO',
    prioridade: 'P1',
  ),
  evolucaoInteligente: _emptyEvolucaoFixture,
  aderenciaSemanal: AderenciaSemanalBundle.fromLegacyList(
    List.generate(
      7,
      (_) => {'data': '2026-06-01', 'checkins': 0},
    ),
  ),
);

final _beatrizOperacaoFixture = Aluno360Operacao(
  aluno: _beatriz360Fixture.aluno,
  autonomiaResumo: _beatriz360Fixture.autonomiaResumo,
  proximaAcao: _beatriz360Fixture.proximaAcao,
  hasOpenCopilotTask: _beatriz360Fixture.hasOpenCopilotTask,
  aderenciaSemanal: _beatriz360Fixture.aderenciaSemanal,
  hasWearableHistory: _beatriz360Fixture.hasWearableHistory,
  recoverySnapshot: _beatriz360Fixture.recoverySnapshot,
  riscoResumo: _beatriz360Fixture.riscoResumo,
  operacaoUiHints: _beatriz360Fixture.operacaoUiHints,
  openCopilotTasks: _beatriz360Fixture.openCopilotTasks,
);


List<Override> _beatrizOverrides() {
  return [
    _proPlanoFeaturesOverride(),
    aluno360OperacaoBundleProvider(_contactPriorityAlunoId)
        .overrideWith((ref) async => _beatrizOperacaoFixture),
    aluno360EvolucaoBundleProvider(_contactPriorityAlunoId).overrideWith(
      (ref) async => Aluno360Evolucao(
        evolucaoInteligente: _beatriz360Fixture.evolucaoInteligente,
        timelinePreview: _beatriz360Fixture.timelinePreview,
      ),
    ),
    aluno360FerramentasBundleProvider(_contactPriorityAlunoId).overrideWith(
      (ref) async => Aluno360Ferramentas(
        aderenciaSemanal: _beatriz360Fixture.aderenciaSemanal,
        hasWearableHistory: _beatriz360Fixture.hasWearableHistory,
      ),
    ),
    alunoProvider(_contactPriorityAlunoId)
        .overrideWith((ref) async => _beatrizFixture),
    alunoRecoveryProvider(_contactPriorityAlunoId).overrideWith((ref) async => null),
    alunoOpenIaActionsProvider(_contactPriorityAlunoId)
        .overrideWith((ref) async => const []),
    alunoPesoHistoricoProvider(_contactPriorityAlunoId)
        .overrideWith((ref) async => const []),
    alunoEvolucaoInteligenteProvider(_contactPriorityAlunoId)
        .overrideWith((ref) async => _emptyEvolucaoFixture),
    alunoTimeline360PagedProvider(_contactPriorityAlunoId).overrideWith(
      (ref) =>
          Timeline360PagedNotifier(ref, _contactPriorityAlunoId)
            ..state = const AsyncValue.data(Timeline360PagedState(events: [])),
    ),
    alunoCopilotoActionProvider(_contactPriorityAlunoId)
        .overrideWith((ref) async => IaCopilotProximaAcao.empty),
  ];
}

Widget _wrapBeatrizDetail() {
  final router = GoRouter(
    initialLocation: '/alunos/$_contactPriorityAlunoId',
    routes: [
      GoRoute(
        path: '/alunos',
        builder: (_, __) => const SizedBox(),
        routes: [
          GoRoute(
            path: ':id',
            builder:
                (_, state) => AlunoDetailScreen(
                  alunoId: int.parse(state.pathParameters['id']!),
                ),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: _beatrizOverrides(),
    child: MaterialApp.router(routerConfig: router),
  );
}


final _alunoFixture = Aluno(
  id: _alunoId,
  nome: 'Ana Silva',
  email: 'ana@test.com',
  status: 'ATIVO',
  scoreProntidao: 82,
  aderenciaPercent: 74,
  diasSemTreino: 2,
  riscoNivel: 'BAIXO',
  proximoContato: '2026-06-10',
  dataNascimento: '1995-03-15',
  altura: 1.68,
  objetivo: 'Hipertrofia',
);

final _aluno360Fixture = Aluno360(
  aluno: _alunoFixture,
  autonomiaResumo: AlunoAutonomiaResumo(
    alunoId: _alunoId,
    totalEventos: 0,
    vistos: 0,
    cliques: 0,
    concluidos: 0,
  ),
  timelinePreview: const [],
  proximaAcao: ProximaAcaoResumo(
    acao: 'Enviar mensagem de follow-up',
    motivo: 'Contato pendente',
    fonte: 'PADRAO',
    prioridade: 'P2',
  ),
  evolucaoInteligente: _emptyEvolucaoFixture,
  aderenciaSemanal: AderenciaSemanalBundle.fromLegacyList(const [
    {'data': '2026-05-29', 'checkins': 1},
    {'data': '2026-05-30', 'checkins': 0},
    {'data': '2026-05-31', 'checkins': 2},
    {'data': '2026-06-01', 'checkins': 1},
    {'data': '2026-06-02', 'checkins': 0},
    {'data': '2026-06-03', 'checkins': 1},
    {'data': '2026-06-04', 'checkins': 0},
  ]),
);

List<Override> _aluno360Overrides() {
  return [
    _proPlanoFeaturesOverride(),
    aluno360OperacaoBundleProvider(_alunoId).overrideWith((ref) async => _operacaoFixture),
    aluno360EvolucaoBundleProvider(_alunoId).overrideWith(
      (ref) async => Aluno360Evolucao(
        evolucaoInteligente: _aluno360Fixture.evolucaoInteligente,
        timelinePreview: _aluno360Fixture.timelinePreview,
      ),
    ),
    aluno360FerramentasBundleProvider(_alunoId).overrideWith(
      (ref) async => Aluno360Ferramentas(
        aderenciaSemanal: _aluno360Fixture.aderenciaSemanal,
        hasWearableHistory: _aluno360Fixture.hasWearableHistory,
      ),
    ),
    alunoProvider(_alunoId).overrideWith((ref) async => _alunoFixture),
    alunoRecoveryProvider(_alunoId).overrideWith((ref) async => null),
    alunoOpenIaActionsProvider(_alunoId).overrideWith((ref) async => const []),
    alunoPesoHistoricoProvider(_alunoId).overrideWith((ref) async => const []),
    alunoEvolucaoInteligenteProvider(_alunoId)
        .overrideWith((ref) async => _emptyEvolucaoFixture),
    alunoTimeline360PagedProvider(_alunoId).overrideWith(
      (ref) =>
          Timeline360PagedNotifier(ref, _alunoId)
            ..state = const AsyncValue.data(Timeline360PagedState(events: [])),
    ),
    alunoCopilotoActionProvider(_alunoId)
        .overrideWith((ref) async => IaCopilotProximaAcao.empty),
  ];
}

Widget _wrapAlunoDetail({
  required double textScaleFactor,
}) {
  final router = GoRouter(
    initialLocation: '/alunos/$_alunoId',
    routes: [
      GoRoute(
        path: '/alunos',
        builder: (_, __) => const SizedBox(),
        routes: [
          GoRoute(
            path: ':id',
            builder:
                (_, state) => AlunoDetailScreen(
                  alunoId: int.parse(state.pathParameters['id']!),
                ),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: _aluno360Overrides(),
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    ),
  );
}

Future<void> _pumpAlunoDetail(WidgetTester tester, {double textScale = 1.0}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrapAlunoDetail(textScaleFactor: textScale));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}


final _operacaoFixture = Aluno360Operacao(
  aluno: _aluno360Fixture.aluno,
  autonomiaResumo: _aluno360Fixture.autonomiaResumo,
  proximaAcao: _aluno360Fixture.proximaAcao,
  hasOpenCopilotTask: _aluno360Fixture.hasOpenCopilotTask,
  aderenciaSemanal: _aluno360Fixture.aderenciaSemanal,
  hasWearableHistory: _aluno360Fixture.hasWearableHistory,
  recoverySnapshot: _aluno360Fixture.recoverySnapshot,
  riscoResumo: _aluno360Fixture.riscoResumo,
  operacaoUiHints: _aluno360Fixture.operacaoUiHints,
  openCopilotTasks: _aluno360Fixture.openCopilotTasks,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scale in [1.0, 1.25]) {
    testWidgets('Operação tab status + sticky CTA at textScaler $scale', (
      tester,
    ) async {
      await _pumpAlunoDetail(tester, textScale: scale);

      expect(find.byKey(const ValueKey('aluno360_operacao_status')), findsOneWidget);
      expect(find.text('Status operacional'), findsOneWidget);
      expect(find.byType(OperationalMetricTile), findsWidgets);
      expect(find.byKey(const ValueKey('aluno360_operacao_sticky_cta')), findsOneWidget);
      expect(find.text('Enviar mensagem'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('contact priority keeps operational status visible', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapBeatrizDetail());
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Prioridade do dia'), findsOneWidget);
    expect(find.byKey(const ValueKey('aluno360_operacao_status')), findsOneWidget);
    expect(find.text('Status operacional'), findsOneWidget);
    expect(find.text('Gerar com IA'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('Evolução tab empty state shows actionable CTAs', (tester) async {
    await _pumpAlunoDetail(tester);

    await tester.tap(find.text('Evolução'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('aluno360_evolucao_empty')),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('aluno360_evolucao_empty')), findsOneWidget);
    expect(find.text('Pedir check-in'), findsWidgets);
    expect(find.text('Ver treinos'), findsWidgets);
    expect(find.text('Abrir chat'), findsWidgets);

    await tester.ensureVisible(find.byKey(const ValueKey('aluno360_timeline_empty')));
    await tester.pump();

    expect(find.byKey(const ValueKey('aluno360_timeline_empty')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
  });

  for (final scale in [1.0, 1.25, 1.3]) {
    testWidgets('Ferramentas tab modules grid at textScaler $scale', (
      tester,
    ) async {
      await _pumpAlunoDetail(tester, textScale: scale);

      await tester.tap(find.text('Ferramentas'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('aluno360_ferramentas_modulos')), findsOneWidget);
      expect(find.text('Medidas'), findsOneWidget);
      expect(find.text('Idade'), findsOneWidget);
      expect(find.text('Gordura corporal'), findsOneWidget);
      expect(find.text('Composição corporal'), findsOneWidget);
      expect(find.text('Treino & evolução'), findsOneWidget);
      expect(find.text('Perfil & gestão'), findsOneWidget);
      expect(find.text('Treinos'), findsOneWidget);
      expect(find.text('IA Progresso'), findsOneWidget);
      expect(find.text('Gordura'), findsNothing);
      expect(find.text('Gordura corporal'), findsOneWidget);
      expect(find.text('Massa magra'), findsOneWidget);
      expect(find.text('Registrar'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('aluno360_ferramentas_modulos')),
          matching: find.text('Chat'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
