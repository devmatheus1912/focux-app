import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/app_theme.dart';
import 'package:focux_app/features/referral/data/referral_info.dart';
import 'package:focux_app/features/referral/widgets/referral_body.dart';
import 'package:focux_app/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, ReferralInfo info, {VoidCallback? onShare}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      theme: AppTheme.buildTheme(Colors.indigo),
      home: Scaffold(
        body: ReferralBody(
          info: info,
          isDark: false,
          onShare: onShare ?? () {},
          onCopyLink: () {},
        ),
      ),
    ),
  );
}

const _ativa = ReferralInfo(
  codigo: 'ABCD234567',
  usosTotais: 2,
  linkCompartilhamento: 'https://focux.app/cadastro?ref=ABCD234567',
  campanhaAtiva: true,
  recompensasConcedidas: 1,
  recompensasEmAnalise: 1,
  maxRecompensas: 3,
  diasGanhos: 30,
  tetoDias: 90,
  diasPorIndicacao: 30,
  descontoIndicadoPct: 20,
  indicacoes: [
    ReferralIndicacao(
      id: 1,
      nomeMascarado: 'Maria L.',
      status: ReferralIndicacaoStatus.rewardGranted,
      dias: 30,
    ),
    ReferralIndicacao(
      id: 2,
      nomeMascarado: 'Pedro C.',
      status: ReferralIndicacaoStatus.underReview,
      dias: 0,
    ),
  ],
);

void main() {
  testWidgets('painel ativo mostra progresso, lista e aviso de analise', (tester) async {
    var compartilhou = false;
    await _pump(tester, _ativa, onShare: () => compartilhou = true);

    expect(find.text('ABCD234567'), findsOneWidget);
    expect(find.text('1 de 3'), findsOneWidget);
    expect(find.text('30 de 90 dias'), findsOneWidget);
    expect(find.text('Maria L.'), findsOneWidget);
    expect(find.text('+30 dias no seu plano'), findsOneWidget);
    expect(find.text('Em análise de segurança'), findsOneWidget);
    expect(find.textContaining('1 recompensa em análise'), findsOneWidget);
    expect(find.textContaining('20% off'), findsOneWidget);

    await tester.tap(find.text('Copiar convite'));
    expect(compartilhou, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem indicacoes mostra estado vazio', (tester) async {
    await _pump(
      tester,
      const ReferralInfo(
        codigo: 'ABCD234567',
        usosTotais: 0,
        linkCompartilhamento: '',
        campanhaAtiva: true,
        maxRecompensas: 3,
        tetoDias: 90,
        diasPorIndicacao: 30,
      ),
    );
    expect(find.text('Nenhuma indicação ainda'), findsOneWidget);
    expect(find.text('Só o link'), findsNothing);
  });

  testWidgets('limite atingido e campanha pausada avisam no topo', (tester) async {
    await _pump(
      tester,
      const ReferralInfo(
        codigo: 'ABCD234567',
        usosTotais: 4,
        linkCompartilhamento: 'https://x',
        campanhaAtiva: true,
        recompensasConcedidas: 3,
        maxRecompensas: 3,
        diasGanhos: 90,
        tetoDias: 90,
        diasPorIndicacao: 30,
        limiteAtingido: true,
      ),
    );
    expect(find.textContaining('limite de recompensas'), findsOneWidget);

    await _pump(
      tester,
      const ReferralInfo(
        codigo: 'ABCD234567',
        usosTotais: 0,
        linkCompartilhamento: 'https://x',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Campanha pausada'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('3. Você ganha dias extras'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('3. Você ganha dias extras'), findsOneWidget);
  });
}
