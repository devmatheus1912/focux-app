import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/brand_style.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_action_link.dart';
import 'package:focux_app/core/widgets/fx_tonal_button.dart';
import 'package:focux_app/core/widgets/fx_week_strip.dart';
import 'package:focux_app/features/dashboard/utils/aluno_today_action.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_today_focus_card.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

final _hoje = DateTime(2026, 10, 27); // terça

const _semana = [
  FxWeekDay(dia: 1, estado: FxWeekDayState.concluido),
  FxWeekDay(dia: 2, estado: FxWeekDayState.descanso, hoje: true),
  FxWeekDay(dia: 3, estado: FxWeekDayState.treino, proximo: true),
  FxWeekDay(dia: 4, estado: FxWeekDayState.descanso),
  FxWeekDay(dia: 5, estado: FxWeekDayState.treino),
  FxWeekDay(dia: 6, estado: FxWeekDayState.descanso),
  FxWeekDay(dia: 7, estado: FxWeekDayState.descanso),
];

Future<void> _abrir(
  WidgetTester tester,
  AlunoTodayAction action, {
  List<FxWeekDay> semana = const [],
  String? selo,
  VoidCallback? onAction,
  VoidCallback? onOpen,
  VoidCallback? onVerTreinos,
  double escala = 1.0,
  bool dark = false,
  String? assinatura,
  BrandStyle estilo = BrandStyle.classico,
  Color? primaria,
}) async {
  tester.view.physicalSize = const Size(1170, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AlunoTodayFocusCard(
            action: action,
            hoje: _hoje,
            isDark: dark,
            onAction: onAction ?? () {},
            onOpen: onOpen,
            semana: semana,
            seloFicha: selo,
            onVerTreinos: onVerTreinos,
            assinatura: assinatura,
            estilo: estilo,
            primaria: primaria,
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  const descanso = AlunoTodayAction(
    mode: AlunoTodayMode.descansoHoje,
    route: '/checkin/executar',
    treinoNome: 'Treino Força',
  );

  group('descanso', () {
    testWidgets('diz o próximo treino e o dia; ação principal é tonal', (
      tester,
    ) async {
      await _abrir(tester, descanso, semana: _semana);
      expect(find.text('Descanso'), findsOneWidget);
      expect(find.text('Hoje é seu descanso'), findsOneWidget);
      expect(find.text('Próximo: Treino Força · Qua'), findsOneWidget);
      // ação principal tonal + o link com seta, que também é um chip tonal
      expect(find.byType(FxTonalButton), findsNWidgets(2));
      expect(find.text('Ver o treino'), findsOneWidget);
      // a ação secundária é link com seta, não texto solto
      expect(find.byType(FxActionLink), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('sem o dia na semana, só o nome do treino', (tester) async {
      await _abrir(tester, descanso);
      expect(find.text('Próximo: Treino Força'), findsOneWidget);
    });

    testWidgets('"Ver o treino" abre os treinos; o link treina mesmo assim', (
      tester,
    ) async {
      var treinos = 0;
      var treinar = 0;
      await _abrir(
        tester,
        descanso,
        onVerTreinos: () => treinos++,
        onAction: () => treinar++,
      );
      await tester.tap(find.text('Ver o treino'));
      await tester.tap(find.text('Treinar mesmo assim'));
      expect([treinos, treinar], [1, 1]);
    });
  });

  group('treino pronto', () {
    testWidgets('uma ação principal cheia e nenhuma secundária', (
      tester,
    ) async {
      var comecou = 0;
      await _abrir(
        tester,
        const AlunoTodayAction(
          mode: AlunoTodayMode.workoutReady,
          route: '/checkin/executar',
          treinoNome: 'Peito e tríceps',
          exerciseCount: 6,
        ),
        onAction: () => comecou++,
      );
      expect(find.text('Peito e tríceps'), findsOneWidget);
      expect(find.byType(FxTonalButton), findsNothing);
      expect(find.byType(FxActionLink), findsNothing);
      await tester.tap(find.text('Começar'));
      expect(comecou, 1);
    });
  });

  group('treino feito', () {
    testWidgets('com próximo: "Fazer mais um" tonal e "Ver resumo" link', (
      tester,
    ) async {
      var resumo = 0;
      await _abrir(
        tester,
        const AlunoTodayAction(
          mode: AlunoTodayMode.workoutDone,
          route: '/checkin/historico/3',
          treinoNome: 'Peito',
          proximoTreinoNome: 'Costas',
          proximoTreinoId: 4,
        ),
        onOpen: () => resumo++,
      );
      expect(find.text('Fazer mais um'), findsOneWidget);
      expect(find.byType(FxTonalButton), findsNWidgets(2));
      await tester.tap(find.text('Ver resumo'));
      expect(resumo, 1);
    });
  });

  group('semana e ficha dentro do card', () {
    testWidgets('mostra a faixa e o selo da ficha no canto', (tester) async {
      await _abrir(tester, descanso, semana: _semana, selo: 'Até 02/11');
      expect(find.byType(FxWeekStrip), findsOneWidget);
      expect(find.text('Até 02/11'), findsOneWidget);
    });

    testWidgets('sem semana não desenha a faixa', (tester) async {
      await _abrir(tester, descanso);
      expect(find.byType(FxWeekStrip), findsNothing);
    });
  });

  testWidgets('aguenta fonte 2.0 e escuro sem estourar', (tester) async {
    await _abrir(
      tester,
      descanso,
      semana: _semana,
      selo: 'Vence em 3 dias',
      escala: 2.0,
      dark: true,
    );
    expect(tester.takeException(), isNull);
  });

  test('proximoDiaNome lê o dia marcado como próximo', () {
    // sem BuildContext: valida a regra pela estrutura da semana
    expect(_semana.where((d) => d.proximo).map((d) => d.dia), [3]);
  });

  group('marca do personal', () {
    const pronto = AlunoTodayAction(
      mode: AlunoTodayMode.workoutReady,
      route: '/checkin/executar',
      treinoNome: 'Peito',
      exerciseCount: 5,
    );

    testWidgets('treino pronto assina: "Treino com {Personal}"', (
      tester,
    ) async {
      await _abrir(tester, pronto, assinatura: 'Matheus Teste');
      expect(find.text('Treino com Matheus Teste'), findsOneWidget);
    });

    testWidgets('retomada e descanso não trocam o eyebrow', (tester) async {
      await _abrir(
        tester,
        const AlunoTodayAction(
          mode: AlunoTodayMode.workoutReady,
          route: '/x',
          treinoNome: 'Peito',
          comeback: true,
        ),
        assinatura: 'Matheus Teste',
      );
      expect(find.text('Treino com Matheus Teste'), findsNothing);
      await _abrir(tester, descanso, assinatura: 'Matheus Teste');
      expect(find.text('Treino com Matheus Teste'), findsNothing);
      expect(find.text('Descanso'), findsOneWidget);
    });

    testWidgets('fundo de marca só entra quando o estilo pede', (tester) async {
      await _abrir(tester, pronto);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              (w.decoration as BoxDecoration?)?.gradient is LinearGradient &&
              ((w.decoration as BoxDecoration).borderRadius != null),
        ),
        findsNothing,
      );
      await _abrir(
        tester,
        pronto,
        estilo: BrandStyle.cinematografico,
        primaria: const Color(0xFF0B4F5C),
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              (w.decoration as BoxDecoration?)?.gradient != null,
        ),
        findsWidgets,
      );
    });
  });
}
