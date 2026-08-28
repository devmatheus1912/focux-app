import 'dart:io';

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

  testWidgets('FxHomeSheetScaffold mostra título e fecha', (tester) async {
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
                            (ctx) => FxHomeSheetScaffold(
                              isDark: false,
                              title: 'Filtrar alertas',
                              subtitle: 'Mostre só o nível de risco.',
                              leading: const Icon(Icons.filter_list_rounded),
                              scroll: false,
                              child: const Text('Todos'),
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
    expect(find.text('Filtrar alertas'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    expect(find.byType(FxHomeSheetScaffold), findsNothing);
  });

  testWidgets('FxHomeSheetScaffold encolhe com conteúdo curto', (
    tester,
  ) async {
    const screenH = 800.0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, screenH)),
          child: Scaffold(
            body: Builder(
              builder:
                  (context) => TextButton(
                    onPressed:
                        () => showFxHomeSheet<void>(
                          context,
                          builder:
                              (ctx) => FxHomeSheetScaffold(
                                isDark: false,
                                title: 'Ações',
                                subtitle: 'Status, pagamento ou exclusão.',
                                leading: const Icon(Icons.checklist_rounded),
                                child: const Text('Item curto'),
                              ),
                        ),
                    child: const Text('abrir'),
                  ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    final surface = tester.getSize(find.byType(FxHomeSheetSurface));
    expect(surface.height, lessThan(screenH * 0.45));
  });

  test('sheet header is ícone 22 + título ink, sem poço colorido', () {
    final src = File('lib/core/widgets/fx_home_sheet.dart').readAsStringSync();
    expect(src, contains('FocuxHubTypography.sectionTitle'));
    expect(src, contains('FxSettingsLayout.iconSize'));
    expect(src, isNot(contains('BrandPalette.soft')));
    expect(src, isNot(contains('TokensStrip.h2')));
  });
}
