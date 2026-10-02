import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/utils/checkin_resumo.dart';
import 'package:focux_app/features/checkin/widgets/checkin_resumo_view.dart';
import 'package:focux_app/l10n/app_localizations.dart';

const _pr = EvolucaoPerformance(
  tipo: 'CARGA',
  exercicioId: 1,
  exercicioNome: 'Remada',
  valorAnterior: 40,
  valorAtual: 45,
  diferenca: 5,
  unidade: 'kg',
  mensagem: '',
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<CheckinResumoAcao?> _abrir(
  WidgetTester tester,
  CheckinResumo resumo,
) async {
  CheckinResumoAcao? acao;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: Builder(
        builder:
            (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  acao = await showCheckinResumo(context, resumo: resumo);
                },
                child: const Text('abrir'),
              ),
            ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await _settle(tester);
  return acao;
}

void main() {
  testWidgets('mostra números, comparação e recordes', (tester) async {
    await _abrir(
      tester,
      const CheckinResumo(
        treinoNome: 'Costas e Bíceps',
        duracao: Duration(minutes: 52),
        seriesFeitas: 24,
        seriesPlanejadas: 26,
        volumeKg: 2400,
        comparacao: CheckinResumoComparacao.mais(20),
        recordes: [_pr],
      ),
    );
    expect(find.text('Costas e Bíceps'), findsOneWidget);
    expect(find.text('Treino concluído'), findsOneWidget);
    expect(find.text('52 min'), findsOneWidget);
    expect(find.text('24 de 26'), findsOneWidget);
    expect(find.text('2,4 mil kg'), findsOneWidget);
    expect(
      find.text('Você levantou 20% a mais que na última vez'),
      findsOneWidget,
    );
    expect(find.text('Recordes de hoje'), findsOneWidget);
    expect(find.textContaining('Remada'), findsOneWidget);
  });

  testWidgets('primeira vez e destaque sem recorde', (tester) async {
    await _abrir(
      tester,
      const CheckinResumo(
        treinoNome: 'Pernas',
        seriesFeitas: 10,
        seriesPlanejadas: 12,
        comparacao: CheckinResumoComparacao.primeira(),
        destaque: (exercicio: 'Agachamento', deltaKg: 5),
      ),
    );
    expect(
      find.text('Primeira vez nesse treino. Agora tem com o que comparar.'),
      findsOneWidget,
    );
    expect(find.text('Recordes de hoje'), findsNothing);
    expect(find.textContaining('Agachamento'), findsOneWidget);
  });

  testWidgets('Concluir e Ver detalhes devolvem a ação', (tester) async {
    const resumo = CheckinResumo(
      treinoNome: 'Treino A',
      seriesFeitas: 0,
      seriesPlanejadas: 0,
    );
    CheckinResumoAcao? acao;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    acao = await showCheckinResumo(context, resumo: resumo);
                  },
                  child: const Text('abrir'),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await _settle(tester);
    await tester.tap(find.text('Ver detalhes'));
    await _settle(tester);
    expect(acao, CheckinResumoAcao.detalhes);

    await tester.tap(find.text('abrir'));
    await _settle(tester);
    await tester.tap(find.text('Concluir'));
    await _settle(tester);
    expect(acao, CheckinResumoAcao.concluir);
  });

  test('texto da comparação cobre os quatro casos', () {
    final s = lookupS(const Locale('pt'));
    expect(
      checkinResumoComparacaoTexto(s, const CheckinResumoComparacao.menos(8)),
      'Volume 8% abaixo da última vez. Faz parte.',
    );
    expect(
      checkinResumoComparacaoTexto(s, const CheckinResumoComparacao.igual()),
      'Mesmo volume da última vez. Consistência conta.',
    );
    expect(checkinResumoComparacaoTexto(s, null), isNull);
  });
}
