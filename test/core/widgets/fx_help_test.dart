import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_help.dart';

void main() {
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
