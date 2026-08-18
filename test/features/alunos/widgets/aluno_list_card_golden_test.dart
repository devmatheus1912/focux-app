import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/widgets/aluno_list_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final aluno = Aluno(
    id: 7,
    nome: 'Mariana Silva',
    email: 'mariana@test.com',
    status: 'ATIVO',
    objetivo: 'Hipertrofia',
    aderenciaPercent: 72,
    diasSemTreino: 0,
    emRisco: true,
  );

  Widget cardHarness({required bool isDark, bool compact = false}) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: EagleTokens.brandAccent,
            brightness: isDark ? Brightness.dark : Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(
            backgroundColor:
                isDark ? EagleTokens.darkBg : TokensStrip.pageBg,
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: AlunoListCard(
                aluno: aluno,
                compact: compact,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('aluno list card golden at 390px', (tester) async {
    await tester.pumpWidget(cardHarness(isDark: false));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(AlunoListCard),
      matchesGoldenFile('goldens/aluno_list_card_390.png'),
    );
  });

  testWidgets('aluno list card golden dark at 390px', (tester) async {
    await tester.pumpWidget(cardHarness(isDark: true));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(AlunoListCard),
      matchesGoldenFile('goldens/aluno_list_card_390_dark.png'),
    );
  });

  testWidgets('aluno list card compact golden dark at 390px', (tester) async {
    await tester.pumpWidget(cardHarness(isDark: true, compact: true));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(AlunoListCard),
      matchesGoldenFile('goldens/aluno_list_card_compact_390_dark.png'),
    );
  });
}
