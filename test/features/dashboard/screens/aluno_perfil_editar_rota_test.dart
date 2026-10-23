import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/router/app_router_aluno_routes.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/alunos_provider.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:focux_app/features/dashboard/screens/perfil_aluno_editar_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('editar cadastro cobre o perfil e voltar devolve a aba', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final root = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: root,
      initialLocation: '/aluno/perfil',
      routes: buildAlunoRoutes(rootNavigatorKey: root),
    );
    addTearDown(router.dispose);

    final home = AlunoPerfilHomeBundle(
      aluno: Aluno(id: 3, nome: 'Ana', email: 'ana@x.com', status: 'ATIVO'),
      medidas: const [],
      completionPercent: 100,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alunoPerfilHomeProvider.overrideWith((ref) async => home),
          alunoDashboardHomeProvider.overrideWith(
            (ref) => Completer<AlunoDashboardHomeBundle>().future,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Meu perfil').hitTestable(), findsOneWidget);
    expect(find.text('Hoje').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Editar cadastro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PerfilAlunoEditarScreen), findsOneWidget);
    expect(find.text('Editar cadastro').hitTestable(), findsWidgets);
    expect(find.text('Meu perfil').hitTestable(), findsNothing);
    expect(find.text('Hoje').hitTestable(), findsNothing);
    expect(find.text('Treinos').hitTestable(), findsNothing);
    expect(find.text('Saúde').hitTestable(), findsNothing);
    expect(find.text('Chat').hitTestable(), findsNothing);
    expect(find.text('Perfil').hitTestable(), findsNothing);

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PerfilAlunoEditarScreen), findsNothing);
    expect(find.text('Meu perfil').hitTestable(), findsOneWidget);
    expect(find.text('Hoje').hitTestable(), findsOneWidget);
    expect(find.text('Perfil').hitTestable(), findsOneWidget);
  });
}
