import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/ia/models/ia_copilot_proxima_acao.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/providers/alunos_provider.dart';
import 'package:focux_app/features/alunos/screens/aluno_detail_screen.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/providers/evolucao_home_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _alunoId = 42;

final _timelineFixture = List.generate(
  5,
  (i) => Timeline360Event(
    tipo: 'CHECKIN',
    titulo: 'Check-in ${i + 1}',
    corpo: 'Treino concluído',
    meta: 'Peito',
    ocorridoEm: '2026-06-0${i + 1}T10:00:00',
    deepLink: '',
    prioridade: 'P2',
  ),
);

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
  timelinePreview: _timelineFixture,
  proximaAcao: ProximaAcaoResumo(
    acao: 'Enviar mensagem de follow-up',
    motivo: 'Contato pendente',
    fonte: 'PADRAO',
    prioridade: 'P2',
  ),
  evolucaoInteligente: EvolucaoInteligente(
    sinal: 'SEM_DADOS',
    resumo: '',
    volumeSemanal: 0,
    volumeMensal: 0,
    proximaAcao: '',
    sugerirCopiloto: false,
  ),
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

List<Override> _flowOverrides() {
  return [
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
    alunoEvolucaoInteligenteProvider(
      _alunoId,
    ).overrideWith((ref) async => _aluno360Fixture.evolucaoInteligente),
    alunoTimeline360PagedProvider(_alunoId).overrideWith(
      (ref) => Timeline360PagedNotifier(ref, _alunoId)
        ..state = AsyncValue.data(
          Timeline360PagedState(
            events: _timelineFixture,
            hasMore: true,
            nextOffset: 5,
            totalCount: 12,
          ),
        ),
    ),
    alunoCopilotoActionProvider(
      _alunoId,
    ).overrideWith((ref) async => IaCopilotProximaAcao.empty),
    evolucaoHomeProvider(_alunoId).overrideWith(
      (ref) async => const EvolucaoHomeBundle(medidas: [], recordes: []),
    ),
  ];
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

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('coach flow: evolução timeline → histórico 360 paginado', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    // LIFO: unmount before dispose — evita "Cannot add event while adding stream".
    addTearDown(router.dispose);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: _flowOverrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Evolução'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Ver todos os 5 sinais'), findsOneWidget);

    await tester.tap(find.text('Ver todos os 5 sinais'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Histórico 360'), findsOneWidget);
    expect(find.text('12 sinais'), findsOneWidget);
    expect(find.text('Check-in 1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
