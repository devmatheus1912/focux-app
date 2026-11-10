import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/router/estado_da_rota.dart';
import 'package:focux_app/core/router/safe_navigation.dart';
import 'package:focux_app/core/widgets/fx_route_chrome.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';
import 'package:go_router/go_router.dart';

/// FLUTTER-4 / FLUTTER-5: `GoRouterState.of` entrava em laço infinito quando a
/// tela que sai do `ShellRoute` reconstruía. Se o laço voltar, estes testes
/// travam a suíte (laço síncrono não se interrompe); o contrato abaixo é a
/// barreira principal.
enum _Saida { trocaPelaExecucao, fechaEAbre }

class _Previa extends StatelessWidget {
  const _Previa(this.saida);
  final _Saida saida;

  @override
  Widget build(BuildContext context) => FxShellScaffold(
    body: Center(
      child: TextButton(
        onPressed:
            () =>
                saida == _Saida.trocaPelaExecucao
                    ? context.pushReplacement('/checkin/executar', extra: 1)
                    : context.pop(true),
        child: const Text('iniciar'),
      ),
    ),
  );
}

class _Execucao extends StatelessWidget {
  const _Execucao();

  @override
  Widget build(BuildContext context) => FxShellScaffold(
    body: Column(
      children: [
        const Text('executando'),
        TextButton(
          // Mesmo caminho de CheckinScreen._concluir com "Ver detalhes".
          onPressed: () async {
            final router = GoRouter.of(context);
            safePopOrGo(context, '/checkin/treinos');
            await Future<void>.delayed(Duration.zero);
            router.push('/checkin/historico/1');
          },
          child: const Text('detalhes'),
        ),
      ],
    ),
  );
}

GoRouter _router({required _Saida saida, required bool direto}) => GoRouter(
  initialLocation: '/dashboard/aluno',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => shell,
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard/aluno',
              builder:
                  (context, state) => Scaffold(
                    body: TextButton(
                      onPressed: () async {
                        if (direto) {
                          context.push('/checkin/executar', extra: 1);
                          return;
                        }
                        final r = await context.push<bool>('/checkin/treino/1');
                        if (r == true && context.mounted) {
                          context.push('/checkin/executar', extra: 1);
                        }
                      },
                      child: const Text('abrir'),
                    ),
                  ),
            ),
          ],
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => FxRouteChrome(child: child),
      routes: [
        GoRoute(
          path: '/checkin/executar',
          builder: (context, state) => const _Execucao(),
        ),
        GoRoute(
          path: '/checkin/historico/:id',
          builder:
              (context, state) =>
                  const FxShellScaffold(body: Text('detalhe aberto')),
        ),
        GoRoute(
          path: '/checkin/treino/:treinoId',
          builder: (context, state) => _Previa(saida),
        ),
      ],
    ),
  ],
);

Future<void> _frames(WidgetTester tester, int n) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _abrir(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.tap(find.text('abrir'));
  await _frames(tester, 60);
}

void main() {
  testWidgets('Iniciar: a execução entra no lugar da prévia sem travar', (
    tester,
  ) async {
    await _abrir(
      tester,
      _router(saida: _Saida.trocaPelaExecucao, direto: false),
    );
    await tester.tap(find.text('iniciar'));
    await _frames(tester, 100);
    expect(find.text('executando'), findsOneWidget);
  });

  testWidgets('Iniciar: fechar a prévia e abrir a execução não trava', (
    tester,
  ) async {
    await _abrir(tester, _router(saida: _Saida.fechaEAbre, direto: false));
    await tester.tap(find.text('iniciar'));
    await _frames(tester, 100);
    expect(find.text('executando'), findsOneWidget);
  });

  testWidgets('Ver detalhes: fechar a execução e abrir o detalhe não trava', (
    tester,
  ) async {
    await _abrir(tester, _router(saida: _Saida.fechaEAbre, direto: true));
    await tester.tap(find.text('detalhes'));
    await _frames(tester, 100);
    expect(find.text('detalhe aberto'), findsOneWidget);
  });

  testWidgets('rota saindo devolve o último estado guardado', (tester) async {
    final lidos = <String>[];
    final router = GoRouter(
      initialLocation: '/a',
      routes: [
        GoRoute(
          path: '/a',
          builder:
              (context, state) => Scaffold(
                body: TextButton(
                  onPressed: () => context.push('/b'),
                  child: const Text('ir'),
                ),
              ),
        ),
        GoRoute(
          path: '/b',
          builder:
              (context, state) => Builder(
                builder: (context) {
                  lidos.add(uriDaRota(context).path);
                  return Scaffold(
                    body: TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('voltar'),
                    ),
                  );
                },
              ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('ir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('voltar'));
    await tester.pumpAndSettle();
    expect(lidos, isNotEmpty);
    expect(lidos.toSet(), {'/b'});
  });

  test('GoRouterState.of só na porta estado_da_rota.dart', () {
    final fora = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final caminho = f.path.replaceAll('\\', '/');
      if (caminho.endsWith('core/router/estado_da_rota.dart')) continue;
      if (f.readAsStringSync().contains('GoRouterState.of(')) fora.add(caminho);
    }
    expect(
      fora,
      isEmpty,
      reason:
          'Use estadoDaRota/uriDaRota: GoRouterState.of trava a tela que sai '
          'de um ShellRoute (FLUTTER-4/5).',
    );
  });
}
