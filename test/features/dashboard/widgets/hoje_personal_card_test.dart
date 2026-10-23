import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/features/dashboard/data/command_action_item.dart';
import 'package:focux_app/features/dashboard/utils/hoje_personal_card.dart';
import 'package:focux_app/features/dashboard/widgets/hoje_personal_card_view.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('card com ação tem um botão preenchido', (tester) async {
    await tester.pumpWidget(
      _harness(
        card: const HojePersonalCard(
          titulo: 'Hugo',
          frase: 'Contato agora',
          botao: 'Hugo',
          rota: '/alunos/1',
          acao: CommandActionItem(
            icon: 'users',
            title: 'Hugo',
            subtitle: 'Contato agora',
            route: '/alunos/1',
            tone: CommandActionTone.primary,
          ),
        ),
      ),
    );

    expect(find.text('Agora'), findsOneWidget);
    expect(find.text('Hugo'), findsWidgets);
    expect(find.text('Contato agora'), findsOneWidget);
    expect(find.byType(FxLiquidPrimaryButton), findsOneWidget);
    expect(find.text('Ver o painel'), findsOneWidget);
    expect(find.widgetWithText(FxLiquidPrimaryButton, 'Ver o painel'), findsNothing);
  });

  testWidgets('fila vazia não tem botão preenchido', (tester) async {
    await tester.pumpWidget(
      _harness(
        card: const HojePersonalCard(
          titulo: 'Operação sob controle',
          frase: 'Nada para fazer agora.',
          botao: null,
          rota: null,
        ),
      ),
    );

    expect(find.text('Nada para fazer agora.'), findsOneWidget);
    expect(find.byType(FxLiquidPrimaryButton), findsNothing);
    expect(find.text('Ver o painel'), findsOneWidget);
  });
}

Widget _harness({required HojePersonalCard card}) {
  return MaterialApp(
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    locale: const Locale('pt'),
    home: Scaffold(
      body: HojePersonalCardView(
        card: card,
        onAction: () {},
        onVerPainel: () {},
      ),
    ),
  );
}
