import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focux_app/features/alertas/data/alertas_repository.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/providers/aluno_followup_provider.dart';
import 'package:focux_app/features/alunos/utils/aluno360_copilot_logic.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_copilot_executar_confirm.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_copilot_prescription.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_operational_status_section.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_operacao_focus_toggle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final aluno = Aluno(
    id: 42,
    nome: 'Beatriz Costa',
    email: 'beatriz@test.com',
    status: 'ATIVO',
    aderenciaPercent: 42,
    scoreProntidao: 68,
    diasSemTreino: 5,
    emRisco: true,
    riscoNivel: 'MEDIO',
  );

  List<Map<String, dynamic>> weekDataEndingToday() {
    final today = DateTime(2026, 6, 4);
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final iso =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      return {'data': iso, 'checkins': i.isEven ? 1 : 0};
    });
  }

  Widget operationalStatusHarness({
    required bool isDark,
    required Widget child,
  }) {
    return ProviderScope(
      overrides: [
        alertasConfigProvider.overrideWith(
          (ref) async => AlertasConfiguracao(
            diasSemTreino: 7,
            aderenciaMinima: 70,
          ),
        ),
        aluno360OperacaoProvider(42).overrideWith((ref) => null),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('operational status section golden at 390px', (tester) async {
    await tester.pumpWidget(
      operationalStatusHarness(
        isDark: false,
        child: Aluno360OperationalStatusSection(
          aluno: aluno,
          alunoId: 42,
          isDark: false,
          primary: const Color(0xFF12A3A3),
          aderenciaSemanal: weekDataEndingToday(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Aluno360OperationalStatusSection),
      matchesGoldenFile('goldens/aluno360_operational_status_390.png'),
    );
  });

  testWidgets('operational status section golden dark at 390px', (tester) async {
    await tester.pumpWidget(
      operationalStatusHarness(
        isDark: true,
        child: Aluno360OperationalStatusSection(
          aluno: aluno,
          alunoId: 42,
          isDark: true,
          primary: const Color(0xFF12A3A3),
          aderenciaSemanal: weekDataEndingToday(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Aluno360OperationalStatusSection),
      matchesGoldenFile('goldens/aluno360_operational_status_390_dark.png'),
    );
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

    await expectLater(
      find.byType(Aluno360CopilotPrescription),
      matchesGoldenFile('goldens/aluno360_copilot_prescription_390.png'),
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

    await expectLater(
      find.byType(Aluno360CopilotPrescription),
      matchesGoldenFile('goldens/aluno360_copilot_prescription_390_dark.png'),
    );
  });

  testWidgets('operational status empty week golden at 390px', (tester) async {
    await tester.pumpWidget(
      operationalStatusHarness(
        isDark: false,
        child: Aluno360OperationalStatusSection(
          aluno: Aluno(
            id: 42,
            nome: 'Beatriz Costa',
            email: 'beatriz@test.com',
            status: 'ATIVO',
            aderenciaPercent: 0,
            scoreProntidao: 68,
            diasSemTreino: 5,
            emRisco: true,
            riscoNivel: 'MEDIO',
          ),
          alunoId: 42,
          isDark: false,
          primary: const Color(0xFF12A3A3),
          aderenciaSemanal: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Aluno360OperationalStatusSection),
      matchesGoldenFile('goldens/aluno360_operational_status_empty_390.png'),
    );
  });

  testWidgets('focus toggle golden dark active at 390px', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alunoOperacaoFocusModeProvider(42).overrideWith(
            (ref) => AlunoOperacaoFocusModeController(42)..state = true,
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              body: Center(
                child: Aluno360OperacaoFocusModeToggle(
                  alunoId: 42,
                  primary: const Color(0xFF12A3A3),
                  iconOnly: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Aluno360OperacaoFocusModeToggle),
      matchesGoldenFile('goldens/aluno360_focus_toggle_390_dark_active.png'),
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

    await expectLater(
      find.text('Aplicar ajuste de carga (−15%)'),
      matchesGoldenFile('goldens/aluno360_executar_confirm_390.png'),
    );
  });

  testWidgets('focus toggle golden icon-only at 390px', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              body: Center(
                child: Aluno360OperacaoFocusModeToggle(
                  alunoId: 42,
                  primary: const Color(0xFF12A3A3),
                  iconOnly: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Aluno360OperacaoFocusModeToggle),
      matchesGoldenFile('goldens/aluno360_focus_toggle_390.png'),
    );
  });
}
