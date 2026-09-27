import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/auth/session_invalidator.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_insight.dart';
import 'package:focux_app/features/dashboard/utils/aluno_insight_analytics.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_home_insight_line.dart';
import 'package:focux_app/l10n/app_localizations.dart';

const _ritmo = AlunoHomeInsight(
  tipo: AlunoInsightTipo.ritmoCaiu,
  confianca: AlunoInsightConfianca.high,
  chave: 'insightRitmoCaiu',
  params: {'media': '3'},
  titulo: 'Seu ritmo caiu',
  mensagem: 'Nas 4 semanas anteriores, sua média era de 3 treinos por semana.',
);

Future<void> _pump(WidgetTester tester, AlunoHomeInsight insight) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: Scaffold(
        body: AlunoHomeInsightLine(insight: insight, onPrimary: Colors.black54),
      ),
    ),
  );
}

void main() {
  setUp(AlunoInsightAnalytics.resetSessao);

  testWidgets('mostra título e detalhe sem CTA nem toque próprio', (
    tester,
  ) async {
    await _pump(tester, _ritmo);

    expect(find.text('Seu ritmo caiu'), findsOneWidget);
    expect(
      find.text('Nas 4 semanas anteriores, sua média era de 3 treinos por semana.'),
      findsOneWidget,
    );
    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });

  test('visualização conta uma vez por tipo na sessão', () {
    expect(AlunoInsightAnalytics.viewed(_ritmo), isTrue);
    expect(AlunoInsightAnalytics.viewed(_ritmo), isFalse);
    expect(AlunoInsightAnalytics.props(_ritmo), {
      'tipo': 'ritmoCaiu',
      'confianca': 'high',
    });
  });

  test('logout limpa tipos vistos da sessão', () {
    expect(AlunoInsightAnalytics.viewed(_ritmo), isTrue);
    expect(AlunoInsightAnalytics.viewed(_ritmo), isFalse);
    SessionInvalidator.clearTenantMemoryCaches();
    expect(AlunoInsightAnalytics.viewed(_ritmo), isTrue);
  });
}
