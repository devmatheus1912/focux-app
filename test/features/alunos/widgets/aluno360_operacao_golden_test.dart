import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/utils/aluno360_copilot_logic.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_copilot_executar_confirm.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_copilot_prescription.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_operational_status_section.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_student_quick_actions.dart';
import 'package:focux_app/features/alunos/utils/aluno360_operacao_logic.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_operacao_sticky_cta.dart';
import 'package:focux_app/features/alunos/widgets/aluno_operacao_adherence_legend.dart';

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
    final today = DateTime.now();
    final anchor = DateTime(today.year, today.month, today.day);
    return List.generate(7, (i) {
      final day = anchor.subtract(Duration(days: 6 - i));
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

  testWidgets('quick actions golden at 390px', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Aluno360StudentQuickActions(
                aluno: aluno,
                isDark: false,
                primary: const Color(0xFF12A3A3),
                onPassword: () {},
                onEdit: () {},
                onEvolve: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Aluno360StudentQuickActions),
      matchesGoldenFile('goldens/aluno360_quick_actions_390.png'),
    );
  });

  testWidgets('adherence legend golden at 390px', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: AlunoOperacaoAdherenceLegend(
                activeColor: const Color(0xFF22C55E),
                missColor: const Color(0xFFDC6B6B),
                todayRingColor: const Color(0xFF12A3A3),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AlunoOperacaoAdherenceLegend),
      matchesGoldenFile('goldens/aluno360_adherence_legend_390.png'),
    );
  });

  testWidgets('sticky CTA bar golden contact plus task at 390px', (tester) async {
    final stickyAluno = Aluno(
      id: 42,
      nome: 'Beatriz Costa',
      email: 'beatriz@test.com',
      status: 'ATIVO',
      emRisco: true,
      riscoNivel: 'ALTO',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alunoOpenIaActionsProvider(42).overrideWith((ref) async => const []),
          alunoRecoveryProvider(42).overrideWith((ref) async => null),
          alunoCopilotoForceIaProvider(42).overrideWith((ref) => false),
          alunoCopilotCreatingProvider(42).overrideWith((ref) => false),
          aluno360OperacaoProvider(42).overrideWith(
            (ref) => resolveAluno360OperacaoSnapshot(
              aluno: stickyAluno,
              proximaAcao360: const ProximaAcaoResumo(
                acao: 'Contate aluno sobre check-in',
                motivo: 'Sem resposta',
                fonte: 'IA',
                prioridade: 'P1',
                stickyLabel: 'Retomar contato',
                stickyLabelCompact: 'Contato',
              ),
              forceIa: false,
              iaAsync: null,
              hasOpenTask: true,
              followUpDue: false,
            ),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              bottomNavigationBar: Aluno360OperacaoStickyCtaBar(
                aluno: stickyAluno,
                alunoId: 42,
                proximaAcao360: const ProximaAcaoResumo(
                  acao: 'Contate aluno sobre check-in',
                  motivo: 'Sem resposta',
                  fonte: 'IA',
                  prioridade: 'P1',
                  stickyLabel: 'Retomar contato',
                  stickyLabelCompact: 'Contato',
                ),
                hasOpenCopilotTask360: true,
                isDark: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byKey(const ValueKey('aluno360_operacao_sticky_cta')),
      matchesGoldenFile('goldens/aluno360_sticky_cta_contact_task_390.png'),
    );
  });
}
