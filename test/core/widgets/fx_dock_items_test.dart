import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_dock.dart';
import 'package:focux_app/l10n/app_localizations.dart';

import '../../support/dynamic_type_harness.dart';

Widget _app(
  List<FxDockItem> Function(S s) items, {
  int current = 0,
  bool dark = false,
  ValueChanged<int>? onTap,
}) {
  return MaterialApp(
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
    locale: const Locale('pt'),
    supportedLocales: S.supportedLocales,
    localizationsDelegates: S.localizationsDelegates,
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FxDock.sideInset),
          child: Builder(
            builder:
                (context) => FxDock(
                  items: items(S.of(context)),
                  currentIndex: current,
                  onTap: onTap ?? (_) {},
                  isDark: dark,
                ),
          ),
        ),
      ),
    ),
  );
}

List<FxDockItem> _personal(S s) =>
    FxDockItems.personal(s, alunosEmRisco: 3, agendaHoje: 12);
List<FxDockItem> _aluno(S s) => FxDockItems.aluno(s, chatUnread: 12);

void main() {
  for (final tela in kDynamicTypeTelas) {
    for (final (perfil, items) in [
      ('Personal', _personal),
      ('Aluno', _aluno),
    ]) {
      testWidgets('dock $perfil aguenta ${descreverTela(tela)}', (
        tester,
      ) async {
        usarDynamicTypeMaximo(tester, tela);
        await tester.pumpWidget(_app(items));

        expect(tester.takeException(), isNull);
        for (final rotulo in [
          for (final i in items(await _s(tester))) i.label,
        ]) {
          final alvo = tester.getSize(
            find.ancestor(
              of: find.text(rotulo),
              matching: find.byType(InkWell),
            ),
          );
          expect(alvo.height, greaterThanOrEqualTo(48), reason: rotulo);
          expect(alvo.width, greaterThanOrEqualTo(48), reason: rotulo);
        }
      });
    }
  }

  testWidgets('personal: abas e selos de risco e agenda', (tester) async {
    await tester.pumpWidget(_app(_personal));
    for (final r in ['Hoje', 'Alunos', 'Treinos', 'Agenda', 'IA']) {
      expect(find.text(r), findsOneWidget);
    }
    expect(find.text('3'), findsOneWidget); // alunos em risco
    expect(find.text('9+'), findsOneWidget); // agenda do dia passa de 9
  });

  testWidgets('aluno: abas, selo do chat e ícone de uma pessoa só', (
    tester,
  ) async {
    await tester.pumpWidget(_app((s) => FxDockItems.aluno(s, chatUnread: 2)));
    for (final r in ['Hoje', 'Treinos', 'Saúde', 'Chat', 'Perfil']) {
      expect(find.text(r), findsOneWidget);
    }
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Alunos'), findsNothing);
    final s = await _s(tester);
    expect(FxDockItems.aluno(s).last.icon, 'user');
  });

  testWidgets('leitor de tela diz quantas não lidas e quantos em risco', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(_personal));
    expect(find.bySemanticsLabel('Alunos, 3 em risco'), findsOneWidget);
    expect(find.bySemanticsLabel('Agenda, 12 hoje'), findsOneWidget);
    await tester.pumpWidget(_app(_aluno));
    expect(find.bySemanticsLabel('Chat, 12 não lidas'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('só a aba ativa tem a pílula tonal', (tester) async {
    await tester.pumpWidget(_app(_personal, current: 1));
    final pilulas =
        tester
            .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
            .where((c) => c.constraints?.maxWidth == 52)
            .toList();
    final preenchidas = pilulas.where((c) {
      final d = c.decoration as BoxDecoration?;
      return d?.color != null && d!.color != Colors.transparent;
    });
    expect(pilulas, hasLength(5));
    expect(preenchidas, hasLength(1));
  });

  testWidgets('toque troca de aba', (tester) async {
    int? tocado;
    await tester.pumpWidget(_app(_personal, onTap: (i) => tocado = i));
    await tester.tap(find.text('Agenda'));
    expect(tocado, 3);
  });

  test('FxDock não usa poço nem underline de ativo', () {
    final dock = File('lib/core/widgets/fx_dock.dart').readAsStringSync();
    expect(dock, contains('FxSettingsLayout.iconSize'));
    expect(dock, contains('shellClearance'));
    expect(dock, contains('withClampedTextScaling'));
    expect(dock, isNot(contains('glowSize')));
    expect(dock, isNot(contains('RadialGradient')));
    expect(dock, isNot(contains('height: 3,')));
  });
}

Future<S> _s(WidgetTester tester) async {
  await tester.pump();
  return S.of(tester.element(find.byType(FxDock)));
}
