import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:focux_app/features/ia/models/progressao_sugestao.dart';
import 'package:focux_app/features/ia/providers/progressao_sugestoes_provider.dart';
import 'package:focux_app/features/ia/screens/progressao_aceitar_screen.dart';
import 'package:focux_app/features/ia/utils/progressao_aceitar_route_args.dart';

void main() {
  const sugestao = ProgressaoSugestao(
    id: 1,
    alunoId: 12,
    alunoNome: 'Beatriz Carvalho',
    exercicio: 'Supino',
    cargaAtual: '80kg 4x20',
    cargaSugerida: '82,5kg 4x18-20',
    justificativa: 'Ajustar a carga em 2,5kg.',
    deltaKg: 2.5,
  );

  testWidgets('revisão renderiza card com aceitar e rejeitar em 390px', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ProgressaoAceitarScreen(),
        ),
      ],
    );
    router.go(
      '/',
      extra: const ProgressaoAceitarRouteArgs(
        alunoId: 12,
        alunoNome: 'Beatriz Carvalho',
      ).toExtra(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressaoSugestoesProvider(12).overrideWith(
            (ref) async => [sugestao],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Supino'), findsOneWidget);
    expect(find.textContaining('82,5kg'), findsOneWidget);
    expect(find.text('Aplicar 1 selecionada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sugestão fora do treino troca Aceitar por Abrir treino', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ProgressaoAceitarScreen(),
        ),
      ],
    );
    router.go(
      '/',
      extra: const ProgressaoAceitarRouteArgs(
        alunoId: 12,
        alunoNome: 'Beatriz Carvalho',
      ).toExtra(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressaoSugestoesProvider(12).overrideWith(
            (ref) async => [
              const ProgressaoSugestao(
                id: 2,
                alunoId: 12,
                exercicio: 'Remada',
                cargaAtual: '40 kg · 3×10',
                cargaSugerida: '42,5 kg · 3×10',
                status: ProgressaoSugestao.statusNaoEncontrada,
              ),
            ],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aceitar'), findsNothing);
    expect(find.text('Abrir treino'), findsOneWidget);
    expect(find.textContaining('Aceitar todas'), findsNothing);
    expect(find.text('1 sugestão fora do treino ativo'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
    expect(find.text('Descartar todas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pendentes vêm antes das que estão fora do treino', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ProgressaoAceitarScreen(),
        ),
      ],
    );
    router.go(
      '/',
      extra: const ProgressaoAceitarRouteArgs(alunoId: 12, alunoNome: 'Beatriz').toExtra(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressaoSugestoesProvider(12).overrideWith(
            (ref) async => [
              const ProgressaoSugestao(
                id: 2,
                alunoId: 12,
                exercicio: 'Remada',
                cargaAtual: '40 kg · 3×10',
                cargaSugerida: '42,5 kg · 3×10',
                status: ProgressaoSugestao.statusNaoEncontrada,
              ),
              sugestao,
            ],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final supino = tester.getTopLeft(find.text('Supino')).dy;
    final remada = tester.getTopLeft(find.text('Remada')).dy;
    expect(supino, lessThan(remada));
    expect(find.text('Aplicar 1 selecionada'), findsOneWidget);
  });

  Future<void> abrir(WidgetTester tester, List<ProgressaoSugestao> lista) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ProgressaoAceitarScreen(),
        ),
      ],
    );
    router.go(
      '/',
      extra: const ProgressaoAceitarRouteArgs(
        alunoId: 12,
        alunoNome: 'Julio',
      ).toExtra(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressaoSugestoesProvider(12).overrideWith((ref) async => lista),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ficha sem carga: carga nova vem marcada e o botão aplica', (
    tester,
  ) async {
    await abrir(tester, [
      for (final (i, kg) in [17.0, 9.5].indexed)
        ProgressaoSugestao(
          id: 10 + i,
          alunoId: 12,
          exercicio: 'Crucifixo $i',
          cargaAtual: '4×8-12',
          cargaSugerida: '${kg.toString().replaceAll('.0', '').replaceAll('.', ',')} kg · 4×8-10',
          cargaSugeridaKg: kg,
          treinoNome: 'A · Peito e tríceps',
        ),
    ]);

    expect(find.text('2 mudanças'), findsOneWidget);
    expect(find.text('2 cargas novas'), findsOneWidget);
    expect(find.text('Sem carga  →  '), findsNothing);
    expect(find.textContaining('Sem carga'), findsNWidgets(2));
    expect(find.text('Carga nova'), findsNWidgets(2));
    expect(find.text('4×8-12  →  4×8-10'), findsNWidgets(2));
    expect(find.byType(Checkbox), findsNWidgets(2));
    expect(find.text('Aplicar 2 selecionadas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tudo igual: sem botão morto e a nota explica', (tester) async {
    await abrir(tester, [
      const ProgressaoSugestao(
        id: 30,
        alunoId: 12,
        exercicio: 'Leg press',
        cargaAtual: '100 kg · 4×10',
        cargaSugerida: '100 kg · 4×10',
        cargaAnteriorKg: 100,
        cargaSugeridaKg: 100,
      ),
    ]);

    expect(find.text('Nenhuma mudança'), findsOneWidget);
    expect(find.text('Marque o que aplicar'), findsNothing);
    expect(
      find.text('Nada para aplicar: o que a IA sugeriu já está no treino.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
