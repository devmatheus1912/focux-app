@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_dock.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/tolerant_golden_comparator.dart';

Widget _app({
  required bool aluno,
  required bool dark,
  required int atual,
  double escala = 1.0,
}) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: EagleTokens.brandAccent,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      useMaterial3: true,
    ),
    locale: const Locale('pt'),
    supportedLocales: S.supportedLocales,
    localizationsDelegates: S.localizationsDelegates,
    builder:
        (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(escala)),
          child: child!,
        ),
    home: Scaffold(
      backgroundColor: dark ? const Color(0xFF14161A) : const Color(0xFFF6F4FA),
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(FxDock.sideInset),
          child: Builder(
            builder:
                (context) => FxDock(
                  items:
                      aluno
                          ? FxDockItems.aluno(S.of(context), chatUnread: 3)
                          : FxDockItems.personal(
                            S.of(context),
                            alunosEmRisco: 4,
                            agendaHoje: 6,
                          ),
                  currentIndex: atual,
                  onTap: (_) {},
                  isDark: dark,
                ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  Future<void> abrir(WidgetTester tester, Widget app) async {
    await tester.binding.setSurfaceSize(const Size(390, 140));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app);
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('barra do personal (claro)', (tester) async {
    await abrir(tester, _app(aluno: false, dark: false, atual: 1));
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/dock_personal_390.png',
    );
  });

  testWidgets('barra do personal (escuro)', (tester) async {
    await abrir(tester, _app(aluno: false, dark: true, atual: 0));
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/dock_personal_390_dark.png',
    );
  });

  testWidgets('barra do aluno (claro)', (tester) async {
    await abrir(tester, _app(aluno: true, dark: false, atual: 3));
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/dock_aluno_390.png',
    );
  });

  testWidgets('barra do aluno (fonte 1.3)', (tester) async {
    await abrir(tester, _app(aluno: true, dark: false, atual: 4, escala: 1.3));
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/dock_aluno_390_scale13.png',
    );
  });
}
