import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/operational_metric_tile.dart';
import 'package:focux_app/features/alertas/data/alertas_repository.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/providers/aluno_followup_provider.dart';
import 'package:focux_app/features/alunos/providers/alunos_provider.dart';
import 'package:focux_app/features/alunos/screens/aluno_detail_screen.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:go_router/go_router.dart';

const _alunoId = 42;

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

final _emptyEvolucaoFixture = EvolucaoInteligente(
  sinal: 'SEM_DADOS',
  resumo: '',
  volumeSemanal: 0,
  volumeMensal: 0,
  proximaAcao: '',
  sugerirCopiloto: false,
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
  aderenciaSemanal: const [
    {'data': '2026-05-29', 'checkins': 1},
    {'data': '2026-05-30', 'checkins': 0},
    {'data': '2026-05-31', 'checkins': 2},
    {'data': '2026-06-01', 'checkins': 1},
    {'data': '2026-06-02', 'checkins': 0},
    {'data': '2026-06-03', 'checkins': 1},
    {'data': '2026-06-04', 'checkins': 0},
  ],
);

List<Override> _aluno360Overrides() {
  return [
    aluno360Provider(_alunoId).overrideWith((ref) async => _aluno360Fixture),
    alunoProvider(_alunoId).overrideWith((ref) async => _alunoFixture),
    alunoRecoveryProvider(_alunoId).overrideWith((ref) async => null),
    alunoOpenIaActionsProvider(_alunoId).overrideWith((ref) async => const []),
    alunoMedidasResumoProvider(_alunoId).overrideWith((ref) async => null),
    alunoPesoHistoricoProvider(_alunoId).overrideWith((ref) async => const []),
    alunoCopilotoActionProvider(_alunoId).overrideWith((ref) async => const {}),
    alertasConfigProvider.overrideWith(
      (ref) async => AlertasConfiguracao(
        diasSemTreino: 7,
        aderenciaMinima: 70,
      ),
    ),
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

void main() {
  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('Operação tab status + sticky CTA at textScaler $scale', (
      tester,
    ) async {
      await _pumpAlunoDetail(tester, textScale: scale);

      expect(find.byKey(const ValueKey('aluno360_operacao_status')), findsOneWidget);
      expect(find.text('Status operacional'), findsOneWidget);
      expect(find.byType(OperationalMetricTile), findsWidgets);
      expect(find.byKey(const ValueKey('aluno360_operacao_sticky_cta')), findsOneWidget);
      expect(find.text('Enviar mensagem'), findsWidgets);
      if (scale == 1.0) {
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('Evolução tab empty state shows actionable CTAs', (tester) async {
    await _pumpAlunoDetail(tester);

    await tester.tap(find.text('Evolução'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('aluno360_evolucao_empty')), findsOneWidget);
    expect(find.text('Sem sinais de evolução ainda'), findsOneWidget);
    expect(find.text('Pedir check-in'), findsWidgets);
    expect(find.text('Ver treinos'), findsWidgets);

    await tester.ensureVisible(find.byKey(const ValueKey('aluno360_timeline_empty')));
    await tester.pump();

    expect(find.byKey(const ValueKey('aluno360_timeline_empty')), findsOneWidget);
    expect(find.text('Linha do tempo ainda vazia'), findsOneWidget);
  });

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('Ferramentas tab modules grid at textScaler $scale', (
      tester,
    ) async {
      await _pumpAlunoDetail(tester, textScale: scale);

      await tester.tap(find.text('Ferramentas'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const ValueKey('aluno360_ferramentas_modulos')), findsOneWidget);
      expect(find.text('Módulos'), findsOneWidget);
      expect(find.text('Treinos'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('aluno360_ferramentas_modulos')),
          matching: find.text('Chat'),
        ),
        findsOneWidget,
      );
      if (scale == 1.0) {
        expect(tester.takeException(), isNull);
      }
    });
  }
}
