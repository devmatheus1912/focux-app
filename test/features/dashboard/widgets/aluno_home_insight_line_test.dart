import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_insight.dart';
import 'package:focux_app/features/dashboard/utils/aluno_insight_analytics.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_home_insight_line.dart';
import 'package:focux_app/l10n/app_localizations.dart';

const _pr = AlunoHomeInsight(
  tipo: AlunoInsightTipo.pr,
  confianca: AlunoInsightConfianca.high,
  chave: 'insightPr',
  params: {'exercicio': 'Supino', 'cargaKg': '82.5', 'dias': '2'},
  titulo: 'Novo recorde',
  mensagem: 'Supino: 82,5 kg',
  acao: AlunoInsightAcao(rota: '/checkin/historico', cta: 'Ver histórico'),
);

Future<void> _pump(
  WidgetTester tester,
  AlunoHomeInsight insight,
  ValueChanged<String> onAction,
) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: Scaffold(
        body: AlunoHomeInsightLine(
          insight: insight,
          onPrimary: Colors.black54,
          onAction: onAction,
        ),
      ),
    ),
  );
}

void main() {
  setUp(AlunoInsightAnalytics.resetSessao);

  testWidgets('mostra título, detalhe e CTA; toque navega para a rota', (
    tester,
  ) async {
    String? rota;
    await _pump(tester, _pr, (r) => rota = r);

    expect(find.text('Novo recorde'), findsOneWidget);
    expect(find.text('Supino: 82,5 kg · há 2 dias'), findsOneWidget);
    expect(find.text('Ver histórico'), findsOneWidget);

    await tester.tap(find.byType(AlunoHomeInsightLine));
    expect(rota, '/checkin/historico');
  });

  testWidgets('sem ação não mostra CTA e não é botão', (tester) async {
    const semAcao = AlunoHomeInsight(
      tipo: AlunoInsightTipo.dadosInsuficientes,
      confianca: AlunoInsightConfianca.low,
      chave: 'insightDadosInsuficientes',
      titulo: 'Continue treinando',
      mensagem: 'Continue treinando para construirmos seu histórico.',
    );
    var tocou = false;
    await _pump(tester, semAcao, (_) => tocou = true);

    expect(find.text('Continue treinando'), findsOneWidget);
    expect(find.textContaining('Ver '), findsNothing);
    await tester.tap(find.byType(AlunoHomeInsightLine));
    expect(tocou, isFalse);
  });

  test('visualização conta uma vez por tipo na sessão', () {
    expect(AlunoInsightAnalytics.viewed(_pr), isTrue);
    expect(AlunoInsightAnalytics.viewed(_pr), isFalse);
    expect(AlunoInsightAnalytics.props(_pr), {
      'tipo': 'pr',
      'confianca': 'high',
    });
  });
}
