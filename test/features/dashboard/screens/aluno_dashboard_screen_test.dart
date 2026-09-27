import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:focux_app/features/dashboard/screens/aluno_dashboard_screen.dart';
import 'package:focux_app/features/dashboard/utils/aluno_autonomy_analytics.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

AlunoDashboardHomeBundle _home({
  String? anamnesePendente,
  bool comHistorico = true,
}) => AlunoDashboardHomeBundle.fromJson({
  'aluno': {
    'id': 7,
    'nome': 'Ana Souza',
    'email': 'ana@focux.test',
    'status': 'ATIVO',
    'telefone': '11999999999',
    'objetivo': 'Hipertrofia',
    'genero': 'F',
    'peso': 62.5,
    'altura': 1.65,
  },
  'personalBrand': {'nomePersonal': 'Carlos', 'plano': 'PRO'},
  'treinos': [],
  'historicoResumo': [
    if (comHistorico)
      {
        'id': 90,
        'treinoId': 11,
        'treinoNome': 'Treino A',
        'status': 'CONCLUIDO',
        'concluidoEm': '2026-09-22T10:00:00',
        'exercicios': [],
      },
  ],
  'medidas': [
    {'id': 3, 'data': '2026-08-10', 'peso': 62.5},
  ],
  'chat': {'possuiMensagemDoAluno': true, 'naoLidasDoPersonal': 1},
  'coachMensagens': [],
  'upsellPendentes': [],
  'npsDeveResponder': false,
  'streakAtual': 3,
  'volumeSemanaKg': 3200.0,
  'concluidosSemanaIso': 2,
  'frequenciaDias': 3,
  'hasWearableHistory': false,
  'volumePorSemana': [0, 1000, 1500, 0, 2000, 2500, 3000, 3200],
  'forcaPorSemana': [0, 60, 62, 0, 64, 66, 70, 72],
  'forcaDeltaPercent': 2.9,
  'anamnesePendente': anamnesePendente,
});

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AlunoAutonomyAnalytics.resetSessao();
  });

  testWidgets('Home "Hoje" monta cabeçalho, foco, semana e pendências', (
    tester,
  ) async {
    await _pump(tester, const Size(430, 2400), _home());

    expect(find.text('Hoje'), findsWidgets);
    expect(find.text('Olá, Ana'), findsOneWidget);
    expect(find.text('Seu personal: Carlos'), findsOneWidget);
    expect(find.text('Peça seu próximo treino'), findsOneWidget);
    expect(find.text('Sua semana'), findsOneWidget);
    expect(find.text('2 de 3'), findsOneWidget);
    expect(find.text('Evolução'), findsOneWidget);
    expect(find.text('+2,9%'), findsOneWidget);
    expect(find.text('Pendências'), findsOneWidget);
    expect(find.text('Completar perfil'), findsOneWidget);
    expect(find.text('Adicionar foto'), findsOneWidget);
    expect(find.text('Atualizar medidas'), findsOneWidget);
    expect(find.text('Responder o personal'), findsNothing);
    expect(find.text('Anamnese solicitada'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('aviso de anamnese vem do BFF, sem request extra', (
    tester,
  ) async {
    await _pump(
      tester,
      const Size(430, 2400),
      _home(anamnesePendente: 'PRECISA_ATESTADO'),
    );
    expect(find.text('Seu personal pediu atestado'), findsOneWidget);
  });

  testWidgets('sem treino nem histórico o foco guia, sem vazio repetido', (
    tester,
  ) async {
    await _pump(tester, const Size(430, 2400), _home(comHistorico: false));
    expect(find.text('Peça seu próximo treino'), findsOneWidget);
    expect(find.text('Sua semana'), findsNothing);
    expect(find.text('Evolução'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tela estreita não estoura layout', (tester) async {
    await _pump(tester, const Size(320, 2400), _home());
    expect(find.text('Sua semana'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Size size,
  AlunoDashboardHomeBundle home,
) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/dashboard/aluno',
    routes: [
      GoRoute(
        path: '/dashboard/aluno',
        builder: (context, state) => const AlunoDashboardScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [alunoDashboardHomeProvider.overrideWith((ref) async => home)],
      child: MaterialApp.router(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
