import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_detail_ferramentas_tab.dart';

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
    dataNascimento: '1998-04-12',
    altura: 1.65,
    diasSemTreino: 14,
    aderenciaPercent: 0,
    objetivo: 'Hipertrofia',
  );

  final aderenciaSemana = List.generate(
    7,
    (i) => {'data': '2026-06-0${i + 1}', 'checkins': i % 3 == 0 ? 1 : 0},
  );

  Widget ferramentasHarness({
    required bool isDark,
    required Widget child,
    double textScale = 1.0,
    Size size = const Size(390, 1200),
  }) {
    return ProviderScope(
      overrides: [
        alunoMedidasResumoProvider(42).overrideWith((ref) async => null),
        alunoAderenciaSemanalProvider(42).overrideWith(
          (ref) async => aderenciaSemana,
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
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

  Widget ferramentasTab({
    required bool isDark,
    double textScale = 1.0,
    Size size = const Size(390, 1200),
  }) {
    return ferramentasHarness(
      isDark: isDark,
      textScale: textScale,
      size: size,
      child: Aluno360DetailFerramentasTab(
        aluno: aluno,
        alunoId: 42,
        isDark: isDark,
        primary: isDark ? const Color(0xFF7EB8FF) : const Color(0xFF2563EB),
        perfilCompletion: 62,
        animateEntrance: false,
        onEntrancePlayed: () {},
      ),
    );
  }

  testWidgets('ferramentas tab golden at 390px with empty measures', (tester) async {
    await tester.pumpWidget(ferramentasTab(isDark: false));
    await tester.pumpAndSettle();

    expect(find.text('Medidas'), findsOneWidget);
    expect(find.text('IA Progresso'), findsOneWidget);
    expect(find.text('GORDURA'), findsOneWidget);
    expect(find.text('MASSA MAGRA'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(Aluno360DetailFerramentasTab),
      matchesGoldenFile('goldens/aluno360_ferramentas_tab_390.png'),
    );
  });

  testWidgets('ferramentas tab golden dark at 390px', (tester) async {
    await tester.pumpWidget(ferramentasTab(isDark: true));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(Aluno360DetailFerramentasTab),
      matchesGoldenFile('goldens/aluno360_ferramentas_tab_390_dark.png'),
    );
  });

  testWidgets('ferramentas tab golden textScale 1.3 at 390px', (tester) async {
    await tester.pumpWidget(ferramentasTab(isDark: false, textScale: 1.3));
    await tester.pumpAndSettle();

    expect(find.text('IA Progresso'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(Aluno360DetailFerramentasTab),
      matchesGoldenFile('goldens/aluno360_ferramentas_tab_390_scale13.png'),
    );
  });

  testWidgets('ferramentas tab golden tablet at 720px', (tester) async {
    await tester.pumpWidget(
      ferramentasTab(
        isDark: false,
        size: const Size(720, 1400),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Medidas'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(Aluno360DetailFerramentasTab),
      matchesGoldenFile('goldens/aluno360_ferramentas_tab_720.png'),
    );
  });
}
