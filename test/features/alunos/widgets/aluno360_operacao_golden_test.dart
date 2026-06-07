import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focux_app/features/alertas/data/alertas_repository.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/providers/aluno_followup_provider.dart';
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

  testWidgets('operational status section golden at 390px', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alertasConfigProvider.overrideWith(
            (ref) async => AlertasConfiguracao(
              diasSemTreino: 7,
              aderenciaMinima: 70,
            ),
          ),
          aluno360OperacaoProvider(42).overrideWith((ref) {
            return null;
          }),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Aluno360OperationalStatusSection(
                  aluno: aluno,
                  alunoId: 42,
                  isDark: false,
                  primary: const Color(0xFF12A3A3),
                  aderenciaSemanal: List.generate(
                    7,
                    (i) => {
                      'data': '2026-06-0${i + 1}',
                      'checkins': i.isEven ? 1 : 0,
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Aluno360OperationalStatusSection),
      matchesGoldenFile('goldens/aluno360_operational_status_390.png'),
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
