import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_home_sheet.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/features/treinos/widgets/prescription_editor_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _pumpOpen(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('modo editar: inset, exercício, volume e salvar', (tester) async {
    final seriesCtrl = TextEditingController(text: '4');
    final repCtrl = TextEditingController(text: '8-12');
    final descansoCtrl = TextEditingController(text: '75');
    final cargaCtrl = TextEditingController();
    final obsCtrl = TextEditingController();
    final grupoCtrl = TextEditingController(text: '1');
    var saved = false;

    addTearDown(() {
      seriesCtrl.dispose();
      repCtrl.dispose();
      descansoCtrl.dispose();
      cargaCtrl.dispose();
      obsCtrl.dispose();
      grupoCtrl.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
          useMaterial3: true,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final primary = Theme.of(context).colorScheme.primary;
              return TextButton(
                onPressed:
                    () => showFxHomeSheet<void>(
                      context,
                      builder:
                          (ctx) => PrescriptionEditorSheet(
                            isDark: false,
                            primary: primary,
                            ink: EagleTokens.ink,
                            title: 'Editar prescrição',
                            contextSubtitle: 'Supino declinado máquina',
                            presetId: 'hypertrophy',
                            tipoSerie: 'NORMAL',
                            globalPresetMode: false,
                            lastPrescription: null,
                            seriesCtrl: seriesCtrl,
                            repCtrl: repCtrl,
                            descansoCtrl: descansoCtrl,
                            cargaCtrl: cargaCtrl,
                            observacoesCtrl: obsCtrl,
                            grupoSupersetCtrl: grupoCtrl,
                            onPresetSelected: (_) {},
                            onTipoSerieChanged: (_) {},
                            onApplyLastPrescription: () {},
                            expand: true,
                            heightFactor: 0.88,
                            stickyFooter: FxLiquidPrimaryButton(
                              label: 'Salvar prescrição',
                              onPressed: () {
                                saved = true;
                                Navigator.pop(ctx);
                              },
                            ),
                          ),
                    ),
                child: const Text('abrir'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await _pumpOpen(tester);

    expect(find.byType(FxHomeSheetSurface), findsOneWidget);
    expect(find.byType(PrescriptionEditorSheet), findsOneWidget);
    expect(find.text('Editar prescrição'), findsOneWidget);
    expect(find.text('Supino declinado máquina'), findsOneWidget);
    expect(find.text('Volume'), findsOneWidget);
    expect(find.text('Tipo de série'), findsOneWidget);
    expect(find.text('Hipertrofia'), findsOneWidget);
    expect(find.text('Salvar prescrição'), findsOneWidget);

    await tester.tap(find.text('Salvar prescrição'));
    await _pumpOpen(tester);

    expect(saved, isTrue);
    expect(find.byType(PrescriptionEditorSheet), findsNothing);
  });

  testWidgets('modo editar: PopScope bloqueia dismiss quando canPop=false', (
    tester,
  ) async {
    final seriesCtrl = TextEditingController(text: '3');
    final repCtrl = TextEditingController(text: '10');
    final descansoCtrl = TextEditingController(text: '60');
    final cargaCtrl = TextEditingController();
    final obsCtrl = TextEditingController();
    final grupoCtrl = TextEditingController(text: '1');

    addTearDown(() {
      seriesCtrl.dispose();
      repCtrl.dispose();
      descansoCtrl.dispose();
      cargaCtrl.dispose();
      obsCtrl.dispose();
      grupoCtrl.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
          useMaterial3: true,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final primary = Theme.of(context).colorScheme.primary;
              return TextButton(
                onPressed:
                    () => showFxHomeSheet<void>(
                      context,
                      builder:
                          (ctx) => PrescriptionEditorSheet(
                            isDark: false,
                            primary: primary,
                            ink: EagleTokens.ink,
                            title: 'Editar prescrição',
                            contextSubtitle: 'Agachamento',
                            presetId: 'hypertrophy',
                            tipoSerie: 'NORMAL',
                            globalPresetMode: false,
                            lastPrescription: null,
                            seriesCtrl: seriesCtrl,
                            repCtrl: repCtrl,
                            descansoCtrl: descansoCtrl,
                            cargaCtrl: cargaCtrl,
                            observacoesCtrl: obsCtrl,
                            grupoSupersetCtrl: grupoCtrl,
                            onPresetSelected: (_) {},
                            onTipoSerieChanged: (_) {},
                            onApplyLastPrescription: () {},
                            canPop: false,
                            stickyFooter: const SizedBox.shrink(),
                          ),
                    ),
                child: const Text('abrir'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await _pumpOpen(tester);
    expect(find.text('Editar prescrição'), findsOneWidget);

    // Fechar do chrome tenta pop; PopScope(canPop: false) mantém a sheet.
    final close = find.byTooltip('Fechar');
    if (close.evaluate().isNotEmpty) {
      await tester.tap(close);
      await _pumpOpen(tester);
    }
    expect(find.text('Editar prescrição'), findsOneWidget);
  });
}
