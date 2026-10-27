@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/brand_palette.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_week_strip.dart';
import 'package:focux_app/features/dashboard/utils/aluno_today_action.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_personal_card.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_today_focus_card.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/tolerant_golden_comparator.dart';

final _hoje = DateTime(2026, 10, 27);

const _semana = [
  FxWeekDay(dia: 1, estado: FxWeekDayState.concluido),
  FxWeekDay(dia: 2, estado: FxWeekDayState.descanso, hoje: true),
  FxWeekDay(dia: 3, estado: FxWeekDayState.treino, proximo: true),
  FxWeekDay(dia: 4, estado: FxWeekDayState.descanso),
  FxWeekDay(dia: 5, estado: FxWeekDayState.treino),
  FxWeekDay(dia: 6, estado: FxWeekDayState.descanso),
  FxWeekDay(dia: 7, estado: FxWeekDayState.descanso),
];

Widget _app(Widget child, {required bool dark}) => MaterialApp(
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
  home: Scaffold(
    backgroundColor: dark ? const Color(0xFF14161A) : const Color(0xFFF6F4FA),
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  for (final dark in [false, true]) {
    final sufixo = dark ? '_dark' : '';

    testWidgets('card: descanso (escuro: $dark)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 520));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(
          dark: dark,
          Builder(
            builder:
                (context) => AlunoTodayFocusCard(
                  action: const AlunoTodayAction(
                    mode: AlunoTodayMode.descansoHoje,
                    route: '/checkin/executar',
                    treinoNome: 'Treino Força',
                  ),
                  hoje: _hoje,
                  isDark: dark,
                  onAction: () {},
                  semana: _semana,
                  seloFicha: 'Até 14/02',
                ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await expectFocuxGolden(
        find.byType(MaterialApp),
        'goldens/aluno_card_descanso_390$sufixo.png',
      );
    });

    testWidgets('card: treino pronto com marca (escuro: $dark)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(
          dark: dark,
          Column(
            children: [
              AlunoTodayFocusCard(
                action: const AlunoTodayAction(
                  mode: AlunoTodayMode.workoutReady,
                  route: '/checkin/executar',
                  treinoNome: 'Peito e tríceps',
                  exerciseCount: 6,
                ),
                hoje: _hoje,
                isDark: dark,
                onAction: () {},
                semana: _semana,
                seloFicha: 'Até 14/02',
                assinatura: 'Matheus Teste',
                fundoMarca: BrandPalette.gradient(
                  const Color(0xFF1A2332),
                  const Color(0xFFC9A962),
                  dark: dark,
                ),
              ),
              const SizedBox(height: 12),
              AlunoPersonalCard(
                nome: 'Matheus Teste',
                slogan: 'Transformando vidas através do movimento',
                onConversar: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await expectFocuxGolden(
        find.byType(MaterialApp),
        'goldens/aluno_card_pronto_marca_390$sufixo.png',
      );
    });
  }

  testWidgets('card: treino feito', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        dark: false,
        AlunoTodayFocusCard(
          action: const AlunoTodayAction(
            mode: AlunoTodayMode.workoutDone,
            route: '/checkin/historico/3',
            treinoNome: 'Peito',
            proximoTreinoNome: 'Costas',
            proximoTreinoId: 4,
          ),
          hoje: _hoje,
          isDark: false,
          onAction: () {},
          onOpen: () {},
          semana: _semana,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/aluno_card_feito_390.png',
    );
  });
}
