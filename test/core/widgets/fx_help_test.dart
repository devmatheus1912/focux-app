import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/fx_settings_layout.dart';
import 'package:focux_app/core/widgets/fx_help.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_microcopy.dart';

void main() {
  test('glifo help continua o ? no círculo', () {
    final icon = File('lib/core/widgets/fx_icon.dart').readAsStringSync();
    final help = File('lib/core/widgets/fx_help.dart').readAsStringSync();
    final helpStart = icon.indexOf("case 'help':");
    final nextCase = icon.indexOf("case '", helpStart + 1);
    expect(helpStart, greaterThanOrEqualTo(0));
    expect(nextCase, greaterThan(helpStart));
    final block = icon.substring(helpStart, nextCase);
    expect(block, contains('Offset(12, 12), 9'));
    expect(block, contains('Offset(12, 16.5)'));
    expect(help, contains('HapticFeedback.selectionClick()'));
    expect(help, isNot(contains('FxSettingsGroup')));
    expect(help, contains('FxHelpTipRow'));
    expect(FxHelpChrome.glyphSize, FxSettingsLayout.iconSize);
    expect(FxHelpChrome.iconName, 'help');
  });

  test('Home help tem tips inset e footnote, sem muro no subtítulo', () {
    final home =
        File(
          'lib/features/dashboard/widgets/dashboard_home_help_sheet.dart',
        ).readAsStringSync();
    expect(home, contains('FxHelpTip'));
    expect(home, contains('footer:'));
    expect(home, isNot(contains('extra:')));
    expect(DashboardMicrocopy.helpHomeTitle, 'Como usar o Hoje');
    expect(
      DashboardMicrocopy.helpHomeBody.contains('Foco do dia prioriza'),
      isFalse,
    );
    expect(DashboardMicrocopy.helpHomeFooter, contains('aba IA'));
  });

  testWidgets('FxHelpIconButton abre a sheet com grupo inset e sem Entendi', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => FxHelpIconButton(
                  tooltip: 'Ajuda',
                  onTap:
                      () => showFxHelpSheet(
                        context,
                        title: 'Como montar este treino',
                        subtitle: 'Adicione e ajuste a prescrição.',
                        tips: const [
                          FxHelpTip(
                            'Adicionar',
                            'O botão principal inclui.',
                            icon: 'plus',
                          ),
                        ],
                        footer: 'Sugestão opcional — você decide se aplica.',
                      ),
                ),
          ),
        ),
      ),
    );

    expect(find.byType(FxHelpIconButton), findsOneWidget);
    await tester.tap(find.byTooltip('Ajuda'));
    await tester.pumpAndSettle();

    expect(find.byType(FxHelpSheetFrame), findsOneWidget);
    expect(find.byType(FxHelpTipRow), findsOneWidget);
    expect(find.text('Como montar este treino'), findsOneWidget);
    expect(find.text('Adicionar'), findsOneWidget);
    expect(find.text('O botão principal inclui.'), findsOneWidget);
    expect(
      find.text('Sugestão opcional — você decide se aplica.'),
      findsOneWidget,
    );
    expect(find.text('Entendi'), findsNothing);
    expect(find.byTooltip('Fechar'), findsOneWidget);
  });

  testWidgets('forceDark pinta a help sheet mesmo com tema claro do SO', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => showFxHelpSheet(
                        context,
                        forceDark: true,
                        title: 'Definir senha',
                        subtitle: 'Dicas rápidas.',
                      ),
                  child: const Text('Abrir'),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    final frame = tester.widget<FxHelpSheetFrame>(
      find.byType(FxHelpSheetFrame),
    );
    expect(frame.isDark, isTrue);
    expect(
      Theme.of(tester.element(find.byType(FxHelpSheetFrame))).brightness,
      Brightness.dark,
    );
  });
}
