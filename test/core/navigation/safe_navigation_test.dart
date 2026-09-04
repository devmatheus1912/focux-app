import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:focux_app/core/router/safe_navigation.dart';

void main() {
  testWidgets('safePopOrGo pops when navigator can pop', (tester) async {
    late BuildContext innerContext;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) {
                innerContext = context;
                return const Text('root');
              },
            ),
          ),
          routes: [
            GoRoute(
              path: 'child',
              builder: (context, state) => Scaffold(
                body: Builder(
                  builder: (context) {
                    innerContext = context;
                    return const Text('child');
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/child');
    await tester.pumpAndSettle();

    safePopOrGo(innerContext, '/fallback');
    await tester.pumpAndSettle();

    expect(find.text('root'), findsOneWidget);
  });

  testWidgets('safePopOrGo devolve result quando pode pop', (tester) async {
    Object? popped;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    popped = await context.push<Object?>('/child');
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
          routes: [
            GoRoute(
              path: 'child',
              builder: (context, state) => Scaffold(
                body: Builder(
                  builder: (context) {
                    return TextButton(
                      onPressed: () =>
                          safePopOrGo(context, '/fallback', result: 'changed'),
                      child: const Text('back'),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();

    expect(popped, 'changed');
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('goPersonalShellTab navigates with context.go', (tester) async {
    late BuildContext navContext;

    final router = GoRouter(
      initialLocation: '/dashboard/personal',
      routes: [
        GoRoute(
          path: '/dashboard/personal',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) {
                navContext = context;
                return const Text('personal');
              },
            ),
          ),
        ),
        GoRoute(
          path: '/alunos',
          builder: (context, state) => const Scaffold(body: Text('alunos')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    goPersonalShellTab(navContext, '/alunos');
    await tester.pumpAndSettle();

    expect(find.text('alunos'), findsOneWidget);
  });
}
