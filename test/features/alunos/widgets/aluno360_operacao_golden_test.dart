@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focux_app/features/alunos/utils/aluno360_copilot_logic.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_copilot_executar_confirm.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_copilot_prescription.dart';

import '../../../support/tolerant_golden_comparator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  testWidgets('copilot prescription golden at 390px', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Aluno360CopilotPrescription(
                title: 'Próximo passo',
                action:
                    'Retomar contato com Beatriz e alinhar expectativa de check-in.',
                reason: 'Wearable desconectado · priorize contato direto hoje.',
                color: const Color(0xFF12A3A3),
                onPrepareMessage: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectFocuxGolden(
      find.byType(Aluno360CopilotPrescription),
      'goldens/aluno360_copilot_prescription_390.png',
    );
  });

  testWidgets('copilot prescription golden dark at 390px', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Aluno360CopilotPrescription(
                title: 'Próximo passo',
                action:
                    'Retomar contato com Beatriz e alinhar expectativa de check-in.',
                reason: 'Wearable desconectado · priorize contato direto hoje.',
                color: const Color(0xFF12A3A3),
                onPrepareMessage: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectFocuxGolden(
      find.byType(Aluno360CopilotPrescription),
      'goldens/aluno360_copilot_prescription_390_dark.png',
    );
  });


  testWidgets('executar confirm sheet golden at 390px', (tester) async {
    const spec = CopilotExecutarAcaoSpec(
      backendTipo: 'REDUZIR_CARGA',
      label: 'Aplicar ajuste de carga (−15%)',
      icon: Icons.fitness_center_rounded,
      executingLabel: 'Aplicando…',
      executingSemantics: 'Aplicando ajuste de carga',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    showCopilotExecutarConfirmSheet(
                      context,
                      spec: spec,
                      primary: const Color(0xFF12A3A3),
                    );
                  },
                  child: const Text('Abrir'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await expectFocuxGolden(
      find.text('Aplicar ajuste de carga (−15%)'),
      'goldens/aluno360_executar_confirm_390.png',
    );
  });


}
