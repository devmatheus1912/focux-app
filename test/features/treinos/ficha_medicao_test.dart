import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/analytics/analytics_service.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/aluno_rotina_screen.dart';
import 'package:focux_app/features/treinos/utils/ficha_medicao.dart';
import 'package:focux_app/features/treinos/utils/semana_da_fila.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

EstadoDaFicha _estado({int sessoes = 2, int prontas = 2}) =>
    EstadoDaFicha(dias: sessoes, sessoes: sessoes, prontas: prontas);

class _Repo extends TreinoRepository {
  _Repo({required this.inicial, required this.depoisDeGravar}) : super(ApiClient());

  final RotinaFila inicial;
  final RotinaFila depoisDeGravar;

  @override
  Future<RotinaFila> buscarRotina(int alunoId) async => inicial;

  @override
  Future<RotinaFila> gravarSemana(int alunoId, List<DiaDaSemana> dias) async =>
      depoisDeGravar;
}

const _pronta = RotinaFila(
  itens: [
    RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 1, nome: 'Treino A', diaSemana: 1, exerciciosCount: 4),
    RotinaItem(id: 2, tipo: RotinaItemTipo.treino, treinoId: 2, nome: 'Treino B', diaSemana: 4, exerciciosCount: 5),
  ],
);

const _incompleta = RotinaFila(
  itens: [
    RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 1, nome: 'Treino A', diaSemana: 1, exerciciosCount: 4),
    RotinaItem(id: 2, tipo: RotinaItemTipo.treino, treinoId: 2, nome: 'Treino B', diaSemana: 4, exerciciosCount: 0),
  ],
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<List<String>> _abrirEConcluir(
  WidgetTester tester, {
  required RotinaFila inicial,
  required RotinaFila depoisDeGravar,
  bool escolherDias = false,
}) async {
  final logs = <String>[];
  final original = debugPrint;
  debugPrint = (String? mensagem, {int? wrapWidth}) {
    if (mensagem != null && mensagem.contains('ficha_primeiro_pronto')) {
      logs.add(mensagem);
    }
  };

  await tester.binding.setSurfaceSize(const Size(430, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/inicio',
    routes: [
      GoRoute(path: '/inicio', builder: (context, state) => const Scaffold(body: Text('inicio'))),
      GoRoute(
        path: '/alunos/:id/rotina',
        builder: (context, state) =>
            const AlunoRotinaScreen(alunoId: 3, alunoNome: 'Ana'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        treinoRepositoryProvider.overrideWithValue(
          _Repo(inicial: inicial, depoisDeGravar: depoisDeGravar),
        ),
      ],
      child: MaterialApp.router(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
          useMaterial3: true,
        ),
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  router.push('/alunos/3/rotina');
  await _settle(tester);
  if (escolherDias) {
    await tester.tap(find.text('4'));
    await _settle(tester);
  }
  await tester.tap(find.text('Pronto'));
  await _settle(tester);
  debugPrint = original;
  return logs;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('FichaMedicao', () {
    final t0 = DateTime(2026, 10, 24, 10);

    test('mede os segundos desde o início, com dias e sessões', () {
      final medicao = FichaMedicao()..iniciar(t0);
      final props = medicao.aoConcluir(_estado(), t0.add(const Duration(seconds: 95)));
      expect(props, {'dias': 2, 'sessoes': 2, 'segundos': 95});
    });

    test('dispara uma vez só', () {
      final medicao = FichaMedicao()..iniciar(t0);
      expect(medicao.aoConcluir(_estado(), t0), isNotNull);
      expect(medicao.aoConcluir(_estado(), t0), isNull);
    });

    test('ficha incompleta ou vazia não conta, e dá para tentar de novo', () {
      final medicao = FichaMedicao()..iniciar(t0);
      expect(medicao.aoConcluir(_estado(prontas: 1), t0), isNull);
      expect(medicao.aoConcluir(_estado(sessoes: 0, prontas: 0), t0), isNull);
      expect(medicao.aoConcluir(_estado(), t0), isNotNull);
    });

    test('sem início (ficha que já veio montada) não mede', () {
      expect(FichaMedicao().aoConcluir(_estado(), t0), isNull);
    });

    test('o início vale o primeiro instante, não o último', () {
      final medicao = FichaMedicao()
        ..iniciar(t0)
        ..iniciar(t0.add(const Duration(minutes: 5)));
      final props = medicao.aoConcluir(_estado(), t0.add(const Duration(seconds: 30)));
      expect(props!['segundos'], 30);
    });
  });

  group('na tela', () {
    testWidgets('ficha vazia montada e concluída dispara o evento uma vez', (tester) async {
      final logs = await _abrirEConcluir(
        tester,
        inicial: RotinaFila.vazia,
        depoisDeGravar: _pronta,
        escolherDias: true,
      );
      expect(logs, hasLength(1));
      expect(logs.single, contains('ficha_primeiro_pronto'));
      expect(logs.single, contains('dias: 2'));
      expect(logs.single, contains('sessoes: 2'));
      expect(logs.single, contains('segundos:'));
      expect(ProductEvents.fichaPrimeiroPronto, 'ficha_primeiro_pronto');
    });

    testWidgets('ficha que já veio montada não dispara', (tester) async {
      final logs = await _abrirEConcluir(
        tester,
        inicial: _pronta,
        depoisDeGravar: _pronta,
      );
      expect(logs, isEmpty);
    });

    testWidgets('com sessão ainda vazia, Pronto não dispara', (tester) async {
      final logs = await _abrirEConcluir(
        tester,
        inicial: RotinaFila.vazia,
        depoisDeGravar: _incompleta,
        escolherDias: true,
      );
      expect(logs, isEmpty);
    });
  });
}
