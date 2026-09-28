import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_error_state.dart';
import 'package:focux_app/features/checkin/screens/meus_treinos_screen.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

final _hoje = DateTime.now();
String _iso(DateTime d) => d.toIso8601String();

/// Início de hoje: evita cair no dia anterior quando o teste roda de madrugada.
final _hojeCedo = DateTime(_hoje.year, _hoje.month, _hoje.day, 0, 1);

Map<String, dynamic> _ficha(
  int id,
  String nome, {
  String status = 'DISPONIVEL',
  int exercicios = 6,
}) => {
  'treinoId': id,
  'treinoNome': nome,
  'status': status,
  'exercicios': [],
  'exerciciosCount': exercicios,
};

AlunoDashboardHomeBundle _home({
  List<Map<String, dynamic>>? treinos,
  List<Map<String, dynamic>> historico = const [],
}) => AlunoDashboardHomeBundle.fromJson({
  'aluno': {'id': 7, 'nome': 'Ana', 'email': 'a@t.com', 'status': 'ATIVO'},
  'personalBrand': {'nomePersonal': 'Carlos'},
  'treinos':
      treinos ??
      [_ficha(1, 'Treino A'), _ficha(2, 'Treino B'), _ficha(3, 'Treino C')],
  'historicoResumo': historico,
  'medidas': [],
  'chat': {'possuiMensagemDoAluno': false, 'naoLidasDoPersonal': 0},
  'volumeSemanaKg': 3200.0,
  'streakAtual': 4,
});

void main() {
  testWidgets('próximo treino: destaque, plano sem ele e nada inventado', (
    tester,
  ) async {
    await _pump(tester, _home());

    expect(find.text('Treinos'), findsWidgets);
    expect(find.text('Próximo treino'), findsOneWidget);
    expect(find.text('Treino A'), findsOneWidget);
    expect(find.text('6 exercícios'), findsWidgets);
    expect(find.text('Iniciar treino'), findsOneWidget);
    expect(find.text('Seu plano'), findsOneWidget);
    expect(find.text('Treino B'), findsOneWidget);
    expect(find.text('Treino C'), findsOneWidget);
    expect(find.text('Últimos treinos'), findsNothing);
    expect(find.textContaining('min'), findsNothing);
    expect(find.textContaining('vídeo'), findsNothing);
    expect(find.textContaining('Consistência'), findsNothing);
    expect(find.textContaining('kg'), findsNothing);
    expect(find.text('Fiz o treino'), findsNothing);
    expect(find.text('Já fiz este treino'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Próximo treino')).dy,
      lessThan(tester.getTopLeft(find.text('Seu plano')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('em andamento mostra N de M e Continuar', (tester) async {
    await _pump(
      tester,
      _home(
        treinos: [
          _ficha(1, 'Treino A'),
          _ficha(2, 'Treino B', status: 'EM_ANDAMENTO'),
        ],
        historico: [
          {
            'id': 90,
            'treinoId': 2,
            'treinoNome': 'Treino B',
            'status': 'EM_ANDAMENTO',
            'iniciadoEm': _iso(_hojeCedo),
            'exerciciosCount': 6,
            'exerciciosConcluidos': 4,
          },
        ],
      ),
    );

    expect(find.text('Em andamento'), findsOneWidget);
    expect(find.text('4 de 6 exercícios'), findsOneWidget);
    expect(find.text('Continuar treino'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('concluído hoje: Ver treino, Depois com Iniciar e últimos', (
    tester,
  ) async {
    final anteontem = _hojeCedo.subtract(const Duration(days: 2));
    await _pump(
      tester,
      _home(
        historico: [
          {
            'id': 91,
            'treinoId': 1,
            'treinoNome': 'Treino A',
            'status': 'CONCLUIDO',
            'iniciadoEm': _iso(_hojeCedo),
            'concluidoEm': _iso(_hojeCedo.add(const Duration(minutes: 52))),
            'exerciciosConcluidos': 6,
          },
          {
            'id': 80,
            'treinoId': 3,
            'treinoNome': 'Treino C',
            'status': 'CONCLUIDO',
            'iniciadoEm': _iso(anteontem),
            'concluidoEm': _iso(anteontem.add(const Duration(seconds: 1))),
            'exerciciosConcluidos': 0,
          },
        ],
      ),
    );

    expect(find.text('Concluído hoje'), findsOneWidget);
    expect(find.text('52 min'), findsOneWidget);
    expect(find.text('Ver treino'), findsOneWidget);
    expect(find.text('Depois'), findsOneWidget);
    expect(find.text('Iniciar'), findsOneWidget);
    expect(find.text('Últimos treinos'), findsOneWidget);
    expect(find.textContaining('Sem séries registradas'), findsOneWidget);
    expect(find.text('Ver histórico'), findsOneWidget);
    expect(find.text('Iniciar treino'), findsNothing);
  });

  testWidgets('sem fichas: vazio honesto com caminho para o personal', (
    tester,
  ) async {
    await _pump(tester, _home(treinos: const []));

    expect(
      find.text('Seu personal ainda não liberou treinos.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Falar com seu personal'));
    await tester.pumpAndSettle();
    expect(find.text('chat'), findsOneWidget);
  });

  testWidgets('carregando: skeleton com leitura própria', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, null, pendente: true);
    await tester.pump(const Duration(seconds: 1));

    expect(find.bySemanticsLabel('Carregando seus treinos'), findsOneWidget);
    expect(find.text('Próximo treino'), findsNothing);
    handle.dispose();
  });

  testWidgets('falha no primeiro carregamento: erro com tentar de novo', (
    tester,
  ) async {
    await _pump(tester, null);

    expect(find.byType(FxErrorState), findsOneWidget);
    expect(find.text('Próximo treino'), findsNothing);
  });

  testWidgets('toque na linha abre a prévia; nada inicia sem o botão', (
    tester,
  ) async {
    await _pump(tester, _home());

    await tester.tap(find.text('Treino B'));
    await tester.pumpAndSettle();
    expect(find.text('previa 2'), findsOneWidget);
    expect(find.text('executar'), findsNothing);
  });

  testWidgets('Iniciar treino abre a execução do próximo', (tester) async {
    await _pump(tester, _home());

    await tester.tap(find.text('Iniciar treino'));
    await tester.pumpAndSettle();
    expect(find.text('executar 1'), findsOneWidget);
  });

  testWidgets('ficha em preparação abre o status, não a prévia', (
    tester,
  ) async {
    await _pump(
      tester,
      _home(
        treinos: [
          _ficha(1, 'Treino A'),
          _ficha(2, 'Treino B', status: 'AGUARDANDO_LIBERACAO', exercicios: 0),
        ],
      ),
    );

    expect(find.text('Em preparação'), findsOneWidget);
    await tester.tap(find.text('Treino B'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Entendi'), findsOneWidget);
    expect(find.text('previa 2'), findsNothing);
  });

  testWidgets('fonte 2x em tela estreita não estoura', (tester) async {
    await _pump(
      tester,
      _home(
        treinos: [
          _ficha(1, 'Treino de força para membros inferiores e core'),
          _ficha(2, 'Treino B'),
        ],
      ),
      size: const Size(320, 2400),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('linhas têm alvo de 48 dp e leitura agrupada', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _home());
    await tester.pump(const Duration(seconds: 1));

    final linha = find.bySemanticsLabel('Treino B, 6 exercícios');
    expect(linha, findsOneWidget);
    expect(tester.getSize(linha).height, greaterThanOrEqualTo(48));
    expect(
      find.bySemanticsLabel('Próximo treino: Treino A, 6 exercícios'),
      findsOneWidget,
    );
    handle.dispose();
  });
}

Future<void> _pump(
  WidgetTester tester,
  AlunoDashboardHomeBundle? home, {
  Size size = const Size(430, 2400),
  double textScale = 1,
  bool pendente = false,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/checkin/treinos',
    routes: [
      GoRoute(
        path: '/checkin/treinos',
        builder: (context, state) => const MeusTreinosScreen(),
      ),
      GoRoute(
        path: '/checkin/treino/:id',
        builder:
            (context, state) => Text('previa ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/checkin/executar',
        builder: (context, state) => Text('executar ${state.extra}'),
      ),
      GoRoute(
        path: '/checkin/historico',
        builder: (context, state) => const Text('historico'),
      ),
      GoRoute(
        path: '/checkin/historico/:id',
        builder: (context, state) => const Text('detalhe'),
      ),
      GoRoute(
        path: '/chat/aluno',
        builder: (context, state) => const Text('chat'),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        alunoDashboardHomeProvider.overrideWith(
          (ref) =>
              pendente
                  ? Completer<AlunoDashboardHomeBundle>().future
                  : home == null
                  ? Future.error(Exception('offline'))
                  : Future.value(home),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        routerConfig: router,
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
