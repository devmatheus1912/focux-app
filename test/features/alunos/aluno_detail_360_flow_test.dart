import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alertas/data/alertas_repository.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/ia/models/ia_copilot_proxima_acao.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/providers/aluno_followup_provider.dart';
import 'package:focux_app/features/alunos/providers/alunos_provider.dart';
import 'package:focux_app/features/alunos/screens/aluno_detail_screen.dart';
import 'package:go_router/go_router.dart';
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
  timelinePreview: const [],
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
    aluno360Provider(_alunoId).overrideWith((ref) async => _aluno360Fixture),
    alunoProvider(_alunoId).overrideWith((ref) async => _alunoFixture),
    alunoRecoveryProvider(_alunoId).overrideWith((ref) async => null),
    alunoOpenIaActionsProvider(_alunoId).overrideWith((ref) async => const []),
    alunoMedidasResumoProvider(_alunoId).overrideWith((ref) async => null),
    alunoPesoHistoricoProvider(_alunoId).overrideWith((ref) async => const []),
    alunoEvolucaoInteligenteProvider(_alunoId).overrideWith(
      (ref) async => _aluno360Fixture.evolucaoInteligente,
    ),
    alunoTimeline360PagedProvider(_alunoId).overrideWith(
      (ref) =>
          Timeline360PagedNotifier(ref, _alunoId)
            ..state = AsyncValue.data(
              Timeline360PagedState(
                events: _timelineFixture,
                hasMore: true,
                nextOffset: 5,
                totalCount: 12,
              ),
            ),
    ),
    alunoCopilotoActionProvider(_alunoId)
        .overrideWith((ref) async => IaCopilotProximaAcao.empty),
    alertasConfigProvider.overrideWith(
      (ref) async => AlertasConfiguracao(
        diasSemTreino: 7,
        aderenciaMinima: 70,
      ),
    ),
  ];
}

Widget _wrapFlowDetail() {
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
    overrides: _flowOverrides(),
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('coach flow: evolução timeline → histórico 360 paginado', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapFlowDetail());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Evolução'));
    await tester.pumpAndSettle();

    expect(find.text('Ver todos os 5 sinais'), findsOneWidget);

    await tester.tap(find.text('Ver todos os 5 sinais'));
    await tester.pumpAndSettle();

    expect(find.text('Histórico 360'), findsOneWidget);
    expect(find.text('12 sinais'), findsOneWidget);
    expect(find.text('Check-in 1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

}
