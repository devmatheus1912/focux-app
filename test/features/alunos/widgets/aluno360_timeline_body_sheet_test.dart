import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_home_sheet.dart';
import 'package:focux_app/core/widgets/fx_settings_tile.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_timeline_card.dart';
import 'package:focux_app/core/theme/brand_palette.dart';

const _longChatBodies = [
  'Primeira mensagem longa sobre treino: me manda carga e repetições para eu ajustar o plano completo.',
  'Segunda mensagem longa sobre alimentação: como está sua rotina alimentar nesta semana de treinos?',
  'Terceira mensagem longa sobre descanso: dormiu bem e está recuperando entre os treinos da semana?',
  'Quarta mensagem longa sobre evolução: sentiu diferença na carga desde a última semana de treino?',
];

void main() {
  testWidgets('body sheet shows chat title without duplication', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    showTimeline360BodySheet(
                      context,
                      const Timeline360Item(
                        at: null,
                        kind: 'Chat',
                        title: 'Chat · Personal',
                        body:
                            'Como foi seu último treino? Me manda carga e repetições.',
                        meta: 'PERSONAL',
                        priority: 'P3',
                        icon: Icons.chat_bubble_outline,
                        color: BrandPalette.defaultPrimary,
                        deepLink: '/alunos/42/chat',
                      ),
                      accent: BrandPalette.defaultPrimary,
                      isDark: false,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Chat · Personal'), findsOneWidget);
    expect(find.textContaining('Chat · Chat'), findsNothing);
    expect(find.text('Abrir chat'), findsOneWidget);
    expect(find.byType(FxHomeSheetSurface), findsOneWidget);
  });

  testWidgets('history sheet closes before body sheet opens', (tester) async {
    final item = Timeline360Item(
      at: null,
      kind: 'Chat',
      title: 'Chat · Personal',
      body:
          '${_longChatBodies.first} '
          'Inclua também como se sentiu nas últimas séries e se teve alguma dor.',
      meta: 'PERSONAL',
      priority: 'P3',
      icon: Icons.chat_bubble_outline,
      color: BrandPalette.defaultPrimary,
      deepLink: '/alunos/42/chat',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (hostContext) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: hostContext,
                      builder:
                          (sheetContext) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Timeline360Tile(
                              item: item,
                              isDark: false,
                              accent: BrandPalette.defaultPrimary,
                              onExpandableTap: (tileContext, tapped) {
                                Navigator.of(tileContext).pop();
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  showTimeline360BodySheet(
                                    hostContext,
                                    tapped,
                                    accent: BrandPalette.defaultPrimary,
                                    isDark: false,
                                  );
                                });
                              },
                            ),
                          ),
                    );
                  },
                  child: const Text('open history'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open history'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico 360'), findsNothing);

    await tester.tap(find.byType(FxSettingsTile));
    await tester.pumpAndSettle();

    expect(find.byType(DraggableScrollableSheet), findsNothing);
    expect(find.byType(FxHomeSheetSurface), findsOneWidget);
    expect(find.text('Abrir chat'), findsOneWidget);
  });

  testWidgets('expandable timeline tile uses disclosure, not chevron', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Timeline360Tile(
            item: Timeline360Item(
              at: null,
              kind: 'Chat',
              title: 'Chat · Personal',
              body:
                  'Primeira mensagem longa sobre treino: me manda carga e '
                  'repetições para eu ajustar o plano completo desta semana.',
              meta: 'PERSONAL',
              priority: 'P3',
              icon: Icons.chat_bubble_outline,
              color: BrandPalette.defaultPrimary,
              deepLink: '/alunos/42/chat',
            ),
            isDark: false,
            accent: BrandPalette.defaultPrimary,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('route-only timeline tile keeps chevron', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Timeline360Tile(
            item: Timeline360Item(
              at: null,
              kind: 'Radar',
              title: 'Radar',
              body: 'Curto.',
              meta: '',
              priority: 'P3',
              icon: Icons.radar_outlined,
              color: Colors.orange,
              deepLink: '/alunos/42',
            ),
            isDark: false,
            accent: BrandPalette.defaultPrimary,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsNothing);
  });
}
