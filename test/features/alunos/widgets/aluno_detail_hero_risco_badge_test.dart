import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/alunos_list_utils.dart';
import 'package:focux_app/features/alunos/widgets/aluno_detail_hero_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final alunoRisco = Aluno(
    id: 7,
    nome: 'Nathalia',
    email: 'nathalia@test.com',
    status: 'ATIVO',
    objetivo: 'MUSCULACAO',
    emRisco: true,
    riscoNivel: 'ALTO',
    aderenciaPercent: 0,
    diasSemTreino: 0,
  );

  Widget harness({required Widget child, required bool isDark}) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 120)),
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('hero risco badge fits compact hero slot without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        isDark: false,
        child: SizedBox(
          height: 58,
          child: AlunoDetailHeroCard(
            aluno: alunoRisco,
            isDark: false,
            primary: EagleTokens.brand,
            compactContactPriority: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Risco'), findsOneWidget);
    expect(find.text('Alto'), findsOneWidget);
  });

  testWidgets('hero risco badge shows legible copy outside scaled identity', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        isDark: false,
        child: AlunoDetailHeroCard(
          aluno: alunoRisco,
          isDark: false,
          primary: EagleTokens.brand,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Risco'), findsOneWidget);
    expect(find.text('Alto'), findsOneWidget);
    expect(find.text('RISCO'), findsNothing);
    expect(find.text('Nathalia'), findsOneWidget);
    expect(find.textContaining('Musculação'), findsOneWidget);

    final semantics = tester.getSemantics(find.byType(AlunoDetailHeroCard));
    expect(semantics.label, contains('Risco operacional Alto'));
  });

  group('alunoHeroRiscoMetricBadgeColors', () {
    test('alto matches list badge palette', () {
      expect(
        alunoHeroRiscoMetricBadgeColors(false, 'Alto'),
        alunoRiscoAltoBadgeColors(false),
      );
    });

    test('medio uses warn family', () {
      final (ink, bg) = alunoHeroRiscoMetricBadgeColors(false, 'Médio');
      expect(ink, const Color(0xFF7A5A00));
      expect(bg, EagleTokens.warnSoft);
    });
  });
}
