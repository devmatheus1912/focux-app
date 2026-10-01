import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/router/safe_navigation.dart';
import 'package:focux_app/core/screens/aluno_shell.dart';
import 'package:focux_app/core/widgets/fx_dock.dart';
import 'package:focux_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:go_router/go_router.dart';

GoRouter _router({Widget? home}) {
  return GoRouter(
    initialLocation: '/dashboard/aluno',
    routes: [
      StatefulShellRoute.indexedStack(
        builder:
            (context, state, navigationShell) =>
                AlunoShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard/aluno',
                builder: (_, __) => home ?? const SizedBox(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/checkin/treinos',
                builder: (_, __) => const SizedBox(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/saude', builder: (_, __) => const SizedBox()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat/aluno',
                builder: (_, __) => const Text('conversa'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/aluno/perfil',
                builder: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [alunoHomeChatUnreadSelectProvider.overrideWithValue(0)],
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('AlunoShell renders FxDock with aluno items', (tester) async {
    await _pump(tester, _router());

    expect(find.byType(FxDock), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('chat aberto pela Home troca de aba e esconde o dock', (
    tester,
  ) async {
    await _pump(
      tester,
      _router(
        home: Builder(
          builder:
              (context) => TextButton(
                onPressed: () => openAlunoRoute(context, '/chat/aluno'),
                child: const Text('falar com o personal'),
              ),
        ),
      ),
    );

    await tester.tap(find.text('falar com o personal'));
    await tester.pumpAndSettle();

    expect(find.text('conversa'), findsOneWidget);
    expect(find.byType(FxDock), findsNothing);
  });

  test('só as abas do dock do aluno trocam de branch', () {
    expect(isAlunoShellTabLocation('/chat/aluno'), isTrue);
    expect(isAlunoShellTabLocation('/saude?x=1'), isTrue);
    expect(isAlunoShellTabLocation('/aluno/habitos'), isFalse);
  });
}
