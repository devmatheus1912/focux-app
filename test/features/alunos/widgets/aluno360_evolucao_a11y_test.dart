import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_detail_evolucao_tab.dart';

void main() {
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
      corpo: 'Beatriz ainda não completou o mapa corporal — vale lembrar hoje.',
      meta: 'Completar mapa corporal',
      ocorridoEm: '2026-06-07T06:15:00',
      deepLink: '/alunos/42/evolucao',
      prioridade: 'P0',
    ),
  ];

  Widget harness(Widget child) {
    return ProviderScope(
      overrides: [
        alunoPesoHistoricoProvider(42).overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
  }

  testWidgets('evolucao tab exposes signal semantics with timeline bridge', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        Aluno360DetailEvolucaoTab(
          aluno: aluno,
          alunoId: 42,
          isDark: false,
          ink: Colors.black,
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
          timeline360Async: AsyncData(timelineEvents),
          animateEntrance: false,
          onEntrancePlayed: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Sem histórico ainda'), findsOneWidget);
    expect(
      find.textContaining('linha do tempo abaixo'),
      findsOneWidget,
    );
    expect(find.text('Radar pede mapa corporal (P0)'), findsNothing);
    expect(
      find.textContaining('O radar também pede mapa corporal (P0)'),
      findsOneWidget,
    );
  });
}
