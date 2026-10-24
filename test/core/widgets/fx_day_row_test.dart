import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_day_row.dart';
import 'package:focux_app/core/widgets/fx_tap_row.dart';

import 'fx_kit_host.dart';

FxDayRow _dia({
  List<FxDaySession> sessoes = const [],
  bool hoje = false,
  VoidCallback? onAdicionar,
}) => FxDayRow(
  dia: 'Seg',
  sessoes: sessoes,
  descansoLabel: 'Descanso',
  adicionarLabel: 'Adicionar treino',
  segundoTreinoLabel: '2º treino',
  hoje: hoje,
  hojeLabel: 'Hoje',
  onAdicionar: onAdicionar,
);

void main() {
  testWidgets('uma linha por sessão, com a contagem de exercícios', (
    tester,
  ) async {
    await tester.pumpWidget(
      kitHost(
        _dia(
          sessoes: [
            FxDaySession(nome: 'Peito', detalhe: '5 exercícios', onTap: () {}),
          ],
        ),
      ),
    );
    expect(find.text('Seg'), findsOneWidget);
    expect(find.byType(FxTapRow), findsOneWidget);
    expect(find.text('5 exercícios'), findsOneWidget);
  });

  testWidgets('a segunda sessão do dia aparece como "2º treino"', (
    tester,
  ) async {
    await tester.pumpWidget(
      kitHost(
        _dia(
          sessoes: [
            const FxDaySession(nome: 'Ombro', detalhe: '4 exercícios'),
            const FxDaySession(nome: 'Posterior', detalhe: '3 exercícios'),
          ],
        ),
      ),
    );
    expect(find.byType(FxTapRow), findsNWidgets(2));
    expect(find.text('2º treino · 3 exercícios'), findsOneWidget);
    expect(find.text('4 exercícios'), findsOneWidget);
  });

  testWidgets('dia vazio com onAdicionar oferece adicionar e toca', (
    tester,
  ) async {
    var toques = 0;
    await tester.pumpWidget(kitHost(_dia(onAdicionar: () => toques++)));
    expect(find.text('Adicionar treino'), findsOneWidget);
    expect(find.text('Descanso'), findsOneWidget);
    await tester.tap(find.text('Adicionar treino'));
    expect(toques, 1);
  });

  testWidgets('dia vazio sem onAdicionar mostra só descanso', (tester) async {
    await tester.pumpWidget(kitHost(_dia()));
    expect(find.text('Descanso'), findsOneWidget);
    expect(find.text('Adicionar treino'), findsNothing);
  });

  testWidgets('hoje fica destacado com o rótulo', (tester) async {
    await tester.pumpWidget(kitHost(_dia(hoje: true)));
    expect(find.text('Hoje'), findsOneWidget);
    await tester.pumpWidget(kitHost(_dia()));
    expect(find.text('Hoje'), findsNothing);
  });

  testWidgets('texto 2.0 sem overflow', (tester) async {
    await tester.pumpWidget(
      kitHost(
        _dia(
          sessoes: [
            const FxDaySession(nome: 'Membros inferiores', detalhe: '12 exercícios'),
          ],
          hoje: true,
        ),
        textScale: 2,
        width: 320,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
