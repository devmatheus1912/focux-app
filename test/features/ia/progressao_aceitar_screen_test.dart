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
    expect(find.text('82,5kg 4x18-20'), findsOneWidget);
    expect(find.text('+2,5 kg'), findsOneWidget);
    expect(find.text('Aceitar'), findsOneWidget);
    expect(find.text('Rejeitar'), findsOneWidget);
    expect(find.text('Aceitar 1 sugestão'), findsOneWidget);
    expect(find.text('Beatriz Carvalho'), findsWidgets);
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
    expect(find.text('Descartar'), findsOneWidget);
    expect(find.textContaining('Não achei no treino'), findsOneWidget);
    expect(find.textContaining('Aceitar todas'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
