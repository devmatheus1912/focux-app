import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_grouped_action_sheet.dart';
import 'package:focux_app/core/widgets/fx_quick_chips.dart';
import 'package:focux_app/core/widgets/fx_sheet_frame.dart';
import 'package:focux_app/core/widgets/fx_sheet_search_field.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(Widget home, {double scale = 1.0}) => MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
    useMaterial3: true,
  ),
  locale: const Locale('pt'),
  supportedLocales: S.supportedLocales,
  localizationsDelegates: S.localizationsDelegates,
  builder:
      (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
  home: Scaffold(body: home),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  void alta(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  Widget abrir(
    Future<Object?> Function(BuildContext) open,
    ValueNotifier<Object?> out,
  ) => Builder(
    builder:
        (context) => Center(
          child: TextButton(
            onPressed: () async => out.value = await open(context),
            child: const Text('abrir'),
          ),
        ),
  );

  FxGroupedActionSheet<String> sheet() => const FxGroupedActionSheet<String>(
    titulo: 'Ações do treino',
    subtitulo: 'Treino A',
    grupos: [
      FxActionGroup('Montar', [
        FxActionItem(
          valor: 'add',
          rotulo: 'Adicionar exercício',
          icone: Icons.add,
        ),
      ]),
      FxActionGroup('Guardar', [
        FxActionItem(
          valor: 'dup',
          rotulo: 'Duplicar treino',
          icone: Icons.copy,
        ),
      ]),
    ],
    destrutiva: FxActionItem(
      valor: 'del',
      rotulo: 'Excluir treino',
      icone: Icons.delete_outline,
    ),
    confirmarTitulo: 'Excluir treino?',
    confirmarMensagem: 'Sai da biblioteca.',
  );

  testWidgets('ação de grupo devolve o valor', (tester) async {
    alta(tester);
    final out = ValueNotifier<Object?>(null);
    await tester.pumpWidget(
      _app(
        abrir(
          (c) =>
              showFxGroupedActionSheet<String>(c, titulo: 'T', grupos: sheet().grupos),
          out,
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await _settle(tester);
    expect(
      find.text('MONTAR'),
      findsNothing,
    ); // título de grupo não é caixa-alta
    expect(find.text('Montar'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
    await tester.tap(find.text('Duplicar treino'));
    await _settle(tester);
    expect(out.value, 'dup');
  });

  testWidgets('destrutiva fica por último, em texto, e pede confirmação', (
    tester,
  ) async {
    alta(tester);
    final out = ValueNotifier<Object?>(null);
    await tester.pumpWidget(
      _app(
        abrir(
          (c) => showFxGroupedActionSheet<String>(
            c,
            titulo: 'Ações do treino',
            grupos: sheet().grupos,
            destrutiva: sheet().destrutiva,
            confirmarTitulo: 'Excluir treino?',
          ),
          out,
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await _settle(tester);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(
      tester.getTopLeft(find.text('Excluir treino')).dy,
      greaterThan(tester.getTopLeft(find.text('Duplicar treino')).dy),
    );
    await tester.tap(find.text('Excluir treino'));
    await _settle(tester);
    expect(find.text('Excluir treino?'), findsOneWidget);
    expect(out.value, isNull); // ainda não confirmou
    await tester.tap(find.text('Excluir treino').last);
    await _settle(tester);
    expect(out.value, 'del');
  });

  testWidgets('moldura: cabeçalho fixo enquanto o corpo rola, rodapé visível', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        FxSheetFrame(
          title: 'Editar prescrição',
          subtitle: 'Abdominal',
          footer: const Text('RODAPÉ'),
          child: Column(
            children: [for (var i = 0; i < 60; i++) Text('linha $i')],
          ),
        ),
      ),
    );
    await _settle(tester);
    final topoAntes = tester.getTopLeft(find.text('Editar prescrição')).dy;
    await tester.drag(find.text('linha 5'), const Offset(0, -400));
    await _settle(tester);
    expect(tester.getTopLeft(find.text('Editar prescrição')).dy, topoAntes);
    expect(find.text('RODAPÉ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('busca com borda e atalhos com "Outro"', (tester) async {
    alta(tester);
    var texto = '';
    int? escolhido = 60;
    var outro = false;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder:
              (context, setState) => Column(
                children: [
                  FxSheetSearchField(
                    dica: 'Buscar…',
                    onChanged: (v) => texto = v,
                  ),
                  FxQuickChips<int>(
                    itens: const [30, 60, 90],
                    selecionado: escolhido,
                    rotuloDe: (v) => '$v s',
                    onSelecionar:
                        (v) => setState(() {
                          escolhido = v;
                          outro = false;
                        }),
                    outroRotulo: 'Outro',
                    onOutro: () => setState(() => outro = true),
                    outroSelecionado: outro,
                  ),
                ],
              ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'polia');
    expect(texto, 'polia');
    final deco = tester.widget<TextField>(find.byType(TextField)).decoration!;
    expect(deco.enabledBorder, isA<OutlineInputBorder>());
    await tester.tap(find.text('90 s'));
    await tester.pump();
    expect(escolhido, 90);
    await tester.tap(find.text('Outro'));
    await tester.pump();
    expect(outro, isTrue);
  });

  for (final scale in [1.3, 2.0]) {
    testWidgets('aguenta fonte $scale', (tester) async {
      tester.view.physicalSize = const Size(360, 690);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final out = ValueNotifier<Object?>(null);
      await tester.pumpWidget(
        _app(
          abrir(
            (c) => showFxGroupedActionSheet<String>(
              c,
              titulo: 'Ações do treino',
              subtitulo: 'Treino Hipertrofia',
              grupos: sheet().grupos,
              destrutiva: sheet().destrutiva,
            ),
            out,
          ),
          scale: scale,
        ),
      );
      await tester.tap(find.text('abrir'));
      await _settle(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
