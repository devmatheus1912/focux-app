import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_copilot_ia_refresh_button.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';

import '../../../support/riverpod_seeds.dart';

Future<void> _pump(WidgetTester tester, String plano) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        seededPlanoFeatures(PlanoFeatures.fromJson({'plano': plano})),
      ],
      child: const MaterialApp(
        locale: Locale('pt'),
        home: Scaffold(
          body: Aluno360CopilotIaRefreshButton(
            alunoId: 7,
            primary: Colors.teal,
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(DashboardHomeClientCache.clear);
  tearDown(DashboardHomeClientCache.clear);

  test('Prioridade do dia por regra não tranca no Free', () {
    final card =
        File(
          'lib/features/alunos/widgets/aluno360_copilot_card.dart',
        ).readAsStringSync();
    expect(card, isNot(contains('Aluno360CopilotLockedSection')));
    expect(card, contains('PlanGate.watch(ref, PlanoRecursoKeys.ia)'));
    expect(
      card,
      contains('iaLiberado && ref.watch(alunoCopilotoForceIaProvider'),
    );
    expect(card, contains('!hasPriorityContent && !iaLoading && iaLiberado'));
    expect(card, contains('copilotFallbackAction(aluno, resumo)'));
  });

  testWidgets('Free: botão de IA com cadeado abre a sheet do Pro', (
    tester,
  ) async {
    await _pump(tester, 'FREE');

    final locked = find.byKey(const ValueKey('aluno360_copilot_ia_locked'));
    expect(locked, findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

    await tester.tap(locked);
    await tester.pumpAndSettle();
    expect(find.text('Desbloqueie no Pro'), findsOneWidget);
    expect(find.text('Prioridade do dia com IA'), findsOneWidget);
  });

  testWidgets('Pro: botão de IA normal, sem cadeado', (tester) async {
    await _pump(tester, 'PRO');
    expect(
      find.byKey(const ValueKey('aluno360_copilot_ia_locked')),
      findsNothing,
    );
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });
}
