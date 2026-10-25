@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/alunos/screens/add_aluno_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/tolerant_golden_comparator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final escuro in [false, true]) {
    for (final preenchido in [false, true]) {
      final nome = preenchido ? 'preenchido' : 'vazio';
      testWidgets('novo aluno, $nome (escuro: $escuro)', (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 1500));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final brilho = escuro ? Brightness.dark : Brightness.light;
        final router = GoRouter(
          initialLocation: '/alunos/novo',
          routes: [
            GoRoute(path: '/alunos/novo', builder: (_, __) => const AddAlunoScreen()),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            child: RepaintBoundary(
              key: const ValueKey('tela'),
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  brightness: brilho,
                  colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent, brightness: brilho),
                  useMaterial3: true,
                ),
                locale: const Locale('pt'),
                supportedLocales: S.supportedLocales,
                localizationsDelegates: S.localizationsDelegates,
                routerConfig: router,
              ),
            ),
          ),
        );
        await tester.pump();
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 120));
        }
        if (preenchido) {
          await tester.enterText(find.byType(TextFormField).at(0), 'Beatriz Andrade');
          await tester.enterText(find.byType(TextFormField).at(1), 'bia@email.com');
          await tester.pump(const Duration(milliseconds: 200));
        }
        await expectFocuxGolden(
          find.byKey(const ValueKey('tela')),
          'goldens/novo_aluno_${nome}_390${escuro ? '_dark' : ''}.png',
        );
      });
    }
  }
}
