import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_home_sheet.dart';

void main() {
  testWidgets('showFxHomeSheet usa card flutuante e fecha no X', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => showFxHomeSheet<void>(
                        context,
                        builder:
                            (ctx) => FxHomeSheetSurface(
                              isDark: false,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const FxHomeSheetHandle(isDark: false),
                                  FxHomeSheetHeader(
                                    isDark: false,
                                    title: 'Todas as prioridades',
                                    subtitle:
                                        'Extra além do que já está na Home.',
                                    leading: const Icon(Icons.flag_outlined),
                                  ),
                                ],
                              ),
                            ),
                      ),
                  child: const Text('abrir'),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byType(FxHomeSheetSurface), findsOneWidget);
    expect(find.text('Todas as prioridades'), findsOneWidget);
    expect(find.byTooltip('Fechar'), findsOneWidget);

    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    expect(find.byType(FxHomeSheetSurface), findsNothing);
  });
}
