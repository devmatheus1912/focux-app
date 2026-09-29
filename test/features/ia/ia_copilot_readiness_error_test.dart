import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/widgets/ia_copilot_insight_widgets.dart';
import 'package:focux_app/l10n/app_localizations.dart';

const _mensagem = 'Não foi possível carregar a prontidão.';

Widget _card({VoidCallback? onRetry}) => MaterialApp(
  locale: const Locale('pt'),
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  home: Scaffold(
    body: SingleChildScrollView(
      child: IaCopilotReadinessCard(
        headline: 'Prontidão',
        modeDisplay: 'Treino',
        icon: Icons.bolt,
        promise: 'Promessa',
        checks: const [],
        alunoNome: 'Aluno',
        recoveryAsync: AsyncError<Never>(
          Exception('boom interno'),
          StackTrace.empty,
        ),
        onRetryRecovery: onRetry,
      ),
    ),
  ),
);

void main() {
  testWidgets('falha da prontidão mostra erro compacto com retry', (
    tester,
  ) async {
    var retried = 0;
    await tester.pumpWidget(_card(onRetry: () => retried++));
    await tester.pumpAndSettle();

    expect(find.text(_mensagem), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing);
    await tester.tap(find.text('Tentar novamente'));
    expect(retried, 1);
  });

  testWidgets('sem retry disponível, só a mensagem', (tester) async {
    await tester.pumpWidget(_card());
    await tester.pumpAndSettle();

    expect(find.text(_mensagem), findsOneWidget);
    expect(find.text('Tentar novamente'), findsNothing);
  });

  testWidgets('mensagem não trunca em 360dp com fonte 1.3', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_card(onRetry: () {}));
    await tester.pumpAndSettle();

    final paragraph = tester.renderObject<RenderParagraph>(
      find.text(_mensagem),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
