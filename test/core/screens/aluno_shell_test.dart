import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/screens/aluno_shell.dart';
import 'package:focux_app/core/widgets/fx_dock.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('AlunoShell renders FxDock with aluno items', (tester) async {
    final router = GoRouter(
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
                  builder: (_, __) => const SizedBox(),
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
                  path: '/aluno/perfil',
                  builder: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
      ),
    );

    expect(find.byType(FxDock), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });
}
