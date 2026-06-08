import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
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
          'Beatriz precisa de uma ação humana hoje: completar mapa corporal.',
      meta: 'Completar mapa corporal',
      ocorridoEm: '2026-06-07T06:15:00',
      deepLink: '/alunos/42',
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

  testWidgets('timeline card golden at 390px', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alunoTimeline360ApiProvider(42).overrideWith((ref) async => timelineEvents),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Aluno360TimelineCard(
                  aluno: aluno,
                  timelineApiAsync: AsyncData(timelineEvents),
                  isDark: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Aluno360TimelineCard),
      matchesGoldenFile('goldens/aluno360_timeline_card_390.png'),
    );
  });

  testWidgets('weight activity card golden at 390px', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alunoPesoHistoricoProvider(42).overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Aluno360WeightActivityCard(
                  aluno: aluno,
                  alunoId: 42,
                  isDark: false,
                  ink: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Aluno360WeightActivityCard),
      matchesGoldenFile('goldens/aluno360_weight_activity_390.png'),
    );
  });
}
