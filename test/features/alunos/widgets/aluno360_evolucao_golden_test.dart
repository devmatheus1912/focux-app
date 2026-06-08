import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_evolucao_inteligente_card.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_evolucao_tab.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_timeline_card.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_weight_activity_card.dart';

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
  );

  final timelineEvents = [
    Timeline360Event(
      tipo: 'RADAR',
      titulo: 'Radar Focux · 19 pts',
      corpo:
          'Beatriz ainda não completou o mapa corporal — vale cobrar hoje.',
      meta: 'Completar mapa corporal',
      ocorridoEm: '2026-06-07T06:15:00',
      deepLink: '/alunos/42/evolucao',
      prioridade: 'P0',
    ),
    Timeline360Event(
      tipo: 'CHAT_PERSONAL',
      titulo: 'Chat · Personal',
      corpo:
          'Oi, Beatriz. Como foi seu último treino? Me manda carga, repetições e qualquer sensação fora do normal para eu ajustar o plano.',
      meta: 'PERSONAL',
      ocorridoEm: '2026-06-05T21:11:00',
      deepLink: '/alunos/42/chat',
      prioridade: 'P3',
    ),
  ];

  Widget evolucaoHarness({
    required bool isDark,
    required Widget child,
    Size size = const Size(390, 844),
  }) {
    return ProviderScope(
      overrides: [
        alunoTimeline360ApiProvider(42).overrideWith((ref) async => timelineEvents),
        alunoPesoHistoricoProvider(42).overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
        home: MediaQuery(
          data: MediaQueryData(size: size),
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

  testWidgets('timeline card golden at 390px', (tester) async {
    await tester.pumpWidget(
      evolucaoHarness(
        isDark: false,
        child: Aluno360TimelineCard(
          aluno: aluno,
          timelineApiAsync: AsyncData(timelineEvents),
          isDark: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Aluno360TimelineCard),
      matchesGoldenFile('goldens/aluno360_timeline_card_390.png'),
    );
  });

  testWidgets('timeline card golden dark at 390px', (tester) async {
    await tester.pumpWidget(
      evolucaoHarness(
        isDark: true,
        child: Aluno360TimelineCard(
          aluno: aluno,
          timelineApiAsync: AsyncData(timelineEvents),
          isDark: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Aluno360TimelineCard),
      matchesGoldenFile('goldens/aluno360_timeline_card_390_dark.png'),
    );
  });

  testWidgets('evolucao inteligente with sparkline golden at 390px', (tester) async {
    const evolucao = EvolucaoInteligente(
      sinal: 'SUBINDO',
      resumo: 'Volume em alta — evolução consistente nas últimas semanas.',
      volumeSemanal: 420,
      volumeMensal: 1680,
      tendenciaVolumePct: 18,
      proximaAcao: 'Reforçar elogio e planejar próxima progressão.',
      sugerirCopiloto: false,
      volumePorSemana: [280, 310, 350, 390, 420, 440],
    );

    await tester.pumpWidget(
      evolucaoHarness(
        isDark: false,
        child: Aluno360EvolucaoInteligenteCard(
          alunoId: 42,
          alunoNome: 'Beatriz Costa',
          evolucaoAsync: const AsyncData(evolucao),
          isDark: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Aluno360EvolucaoInteligenteCard),
      matchesGoldenFile('goldens/aluno360_evolucao_inteligente_390.png'),
    );
  });

  testWidgets('evolucao inteligente golden dark at 390px', (tester) async {
    const evolucao = EvolucaoInteligente(
      sinal: 'SUBINDO',
      resumo: 'Volume em alta — evolução consistente nas últimas semanas.',
      volumeSemanal: 420,
      volumeMensal: 1680,
      tendenciaVolumePct: 18,
      proximaAcao: 'Reforçar elogio e planejar próxima progressão.',
      sugerirCopiloto: false,
      volumePorSemana: [280, 310, 350, 390, 420, 440],
    );

    await tester.pumpWidget(
      evolucaoHarness(
        isDark: true,
        child: Aluno360EvolucaoInteligenteCard(
          alunoId: 42,
          alunoNome: 'Beatriz Costa',
          evolucaoAsync: const AsyncData(evolucao),
          isDark: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Aluno360EvolucaoInteligenteCard),
      matchesGoldenFile('goldens/aluno360_evolucao_inteligente_390_dark.png'),
    );
  });

  testWidgets('evolucao tab golden at 600px tablet', (tester) async {
    await tester.pumpWidget(
      evolucaoHarness(
        isDark: false,
        size: const Size(600, 900),
        child: Aluno360EvolucaoTab(
          evolucaoCard: Aluno360EvolucaoInteligenteCard(
            alunoId: 42,
            alunoNome: 'Beatriz Costa',
            evolucaoAsync: const AsyncData(
              EvolucaoInteligente(
                sinal: 'SEM_DADOS',
                resumo: '',
                volumeSemanal: 0,
                volumeMensal: 0,
                proximaAcao: '',
                sugerirCopiloto: false,
              ),
            ),
            isDark: false,
          ),
          timelineCard: Aluno360TimelineCard(
            aluno: aluno,
            timelineApiAsync: AsyncData(timelineEvents),
            isDark: false,
          ),
          weightCard: Aluno360WeightActivityCard(
            aluno: aluno,
            alunoId: 42,
            isDark: false,
            ink: Colors.black,
          ),
          animateEntrance: false,
          onEntrancePlayed: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Aluno360EvolucaoTab),
      matchesGoldenFile('goldens/aluno360_evolucao_tab_600.png'),
    );
  });

  testWidgets('weight activity card golden at 390px', (tester) async {
    await tester.pumpWidget(
      evolucaoHarness(
        isDark: false,
        child: Aluno360WeightActivityCard(
          aluno: aluno,
          alunoId: 42,
          isDark: false,
          ink: Colors.black,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Aluno360WeightActivityCard),
      matchesGoldenFile('goldens/aluno360_weight_activity_390.png'),
    );
  });

  testWidgets('weight activity card golden dark at 390px', (tester) async {
    await tester.pumpWidget(
      evolucaoHarness(
        isDark: true,
        child: Aluno360WeightActivityCard(
          aluno: aluno,
          alunoId: 42,
          isDark: true,
          ink: Colors.white,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Aluno360WeightActivityCard),
      matchesGoldenFile('goldens/aluno360_weight_activity_390_dark.png'),
    );
  });
}
