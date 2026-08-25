import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/fx_settings_layout.dart';
import 'package:focux_app/core/widgets/fx_help.dart';

void main() {
  test('glifo help é ? outline, sem poço circular', () {
    final icon = File('lib/core/widgets/fx_icon.dart').readAsStringSync();
    final help = File('lib/core/widgets/fx_help.dart').readAsStringSync();
    final helpStart = icon.indexOf("case 'help':");
    final nextCase = icon.indexOf("case '", helpStart + 1);
    expect(helpStart, greaterThanOrEqualTo(0));
    expect(nextCase, greaterThan(helpStart));
    final block = icon.substring(helpStart, nextCase);
    expect(block, isNot(contains('Offset(12, 12), 9')));
    expect(block, contains('Offset(12, 19.55)'));
    expect(help, contains('HapticFeedback.selectionClick()'));
    expect(help, contains('FxHelpChrome.glyphSize'));
    expect(help, contains('BrandPalette.softened'));
    expect(FxHelpChrome.glyphSize, FxSettingsLayout.iconSize);
    expect(FxHelpChrome.iconName, 'help');
  });

  testWidgets('FxHelpIconButton abre a sheet canônica sem Entendi', (
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
                          FxHelpTip('Adicionar', 'O botão principal inclui.'),
                        ],
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
    expect(find.text('Como montar este treino'), findsOneWidget);
    expect(find.text('Adicionar'), findsOneWidget);
    expect(find.text('Entendi'), findsNothing);
    expect(find.byTooltip('Fechar'), findsOneWidget);
  });
}
