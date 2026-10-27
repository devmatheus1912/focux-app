import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_week_strip.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/utils/aluno360_operacao_logic.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_follow_up_card.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_resumo_tab.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _id = 42;

Aluno _hugo({
  bool emRisco = true,
  int? dias = 9,
  int? ader = 12,
  bool inadimplente = false,
}) => Aluno(
  id: _id,
  nome: 'Hugo Silva',
  email: 'hugo@x.com',
  status: 'ATIVO',
  emRisco: emRisco,
  riscoNivel: 'ALTO',
  diasSemTreino: dias,
  aderenciaPercent: ader,
  inadimplente: inadimplente,
  statusFinanceiro: inadimplente ? 'INADIMPLENTE' : 'EM_DIA',
);

final _proxima = ProximaAcaoResumo(
  acao: 'Completar mapa corporal',
  motivo: 'Faltam medidas para ajustar o treino',
  fonte: 'PADRAO',
  prioridade: 'P2',
);

RotinaFila _ficha() => RotinaFila(
  itens: const [
    RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 1, nome: 'Treino A', diaSemana: 1),
    RotinaItem(id: 2, tipo: RotinaItemTipo.treino, treinoId: 2, nome: 'Treino B', diaSemana: 3),
    RotinaItem(id: 3, tipo: RotinaItemTipo.treino, treinoId: 3, nome: 'Treino C', diaSemana: 5),
  ],
);

Future<void> _abrir(
  WidgetTester tester,
  Aluno aluno, {
  RotinaFila? rotina,
  double escala = 1,
  Size tamanho = const Size(390, 1800),
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.binding.setSurfaceSize(tamanho);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Aluno360ResumoTab(
              aluno: aluno,
              alunoId: _id,
              isDark: false,
              primary: const Color(0xFF0B4F5C),
              proximaAcao360: _proxima,
              hasOpenCopilotTask360: false,
              aderenciaSemanal: null,
              recoveryAsync: const AsyncData(null),
              autonomiaResumoAsync: const AsyncLoading(),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/alunos/:id/rotina',
        builder: (_, __) => const Scaffold(body: Text('rota ficha')),
      ),
      GoRoute(
        path: '/alunos/:id/engajamento',
        builder: (_, __) => const Scaffold(body: Text('rota engajamento')),
      ),
      GoRoute(
        path: '/financeiro',
        builder: (_, __) => const Scaffold(body: Text('rota financeiro')),
      ),
    ],
  );
  addTearDown(router.dispose);
  final overrides = <Override>[
    aluno360OperacaoProvider(_id).overrideWith(
      (ref) => resolveAluno360OperacaoSnapshot(
        aluno: aluno,
        proximaAcao360: _proxima,
        forceIa: false,
        iaAsync: null,
        hasOpenTask: false,
        followUpDue: false,
        wearableRelevant: false,
      ),
    ),
    alunoRotinaProvider(_id).overrideWith((ref) async => rotina ?? _ficha()),
  ];
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('Agora: título, motivo real e um verbo que não repete o título', (tester) async {
    await _abrir(tester, _hugo());
    expect(find.text('Agora'), findsOneWidget);
    expect(find.text('Retomar contato'), findsOneWidget);
    expect(find.text('9 dias sem treinar'), findsOneWidget);
    expect(find.text('Chamar'), findsOneWidget);
    // A frase de outra sugestão não vira motivo do contato.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('aluno360_resumo_agora')),
        matching: find.text('Completar mapa corporal'),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ficha: semana em sete dias e "Abrir ficha" leva à ficha', (tester) async {
    await _abrir(tester, _hugo());
    expect(find.text('Ficha de treino'), findsOneWidget);
    expect(find.byType(FxWeekStrip), findsOneWidget);
    for (final dia in ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom']) {
      expect(find.text(dia), findsOneWidget);
    }
    expect(find.text('Ver a ficha'), findsNothing);
    await tester.ensureVisible(find.text('Abrir ficha'));
    await tester.tap(find.text('Abrir ficha'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('rota ficha'), findsOneWidget);
  });

  testWidgets('ficha vazia convida a montar', (tester) async {
    await _abrir(tester, _hugo(), rotina: RotinaFila.vazia);
    expect(find.text('Sem ficha ainda.'), findsOneWidget);
    expect(find.text('Montar ficha'), findsOneWidget);
    expect(find.byType(FxWeekStrip), findsNothing);
  });

  testWidgets('números: zero apagado, nunca "0%" vermelho para quem não treinou', (tester) async {
    await _abrir(tester, _hugo(dias: null, ader: 0));
    // a linha solta saiu: o cartão da ficha já diz que não há ficha
    expect(find.text('Sem treinos ainda.'), findsNothing);
    expect(find.text('Aderência 30 dias'), findsNothing);
  });

  testWidgets('números: com histórico aparecem as três métricas', (tester) async {
    await _abrir(tester, _hugo());
    expect(find.text('Aderência 30 dias'), findsOneWidget);
    expect(find.text('Dias sem treino'), findsOneWidget);
    expect(find.text('Check-ins 7 dias'), findsOneWidget);
    await tester.tap(find.text('Dias sem treino'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('rota engajamento'), findsOneWidget);
  });

  testWidgets('financeiro em atraso ganha a linha Cobrar', (tester) async {
    await _abrir(tester, _hugo(emRisco: false, dias: 1, ader: 80, inadimplente: true));
    expect(find.textContaining('Mensalidade em atraso'), findsWidgets);
    expect(find.text('Cobrar'), findsWidgets);
  });

  testWidgets('próximo contato: sem data convida a agendar', (tester) async {
    await _abrir(tester, _hugo());
    expect(find.text('Próximo contato'), findsOneWidget);
    expect(find.text('Nenhum retorno agendado'), findsOneWidget);
    expect(find.text('Agendar'), findsOneWidget);
  });

  testWidgets('sugestão do copiloto aparece como uma linha', (tester) async {
    await _abrir(tester, _hugo());
    expect(find.text('Sugestão do copiloto'), findsOneWidget);
    expect(find.text('Completar mapa corporal'), findsOneWidget);
  });

  testWidgets('não existe mais o painel nem "Mais ações" no corpo da aba', (tester) async {
    await _abrir(tester, _hugo());
    expect(find.text('Mais ações'), findsNothing);
    expect(find.text('Status operacional'), findsNothing);
    expect(find.text('Ver a ficha'), findsNothing);
  });

  testWidgets('texto 2.0 em tela estreita não estoura', (tester) async {
    await _abrir(
      tester,
      _hugo(),
      escala: 2,
      tamanho: const Size(320, 3600),
    );
    expect(tester.takeException(), isNull);
  });

  group('Aluno360FollowUpCard.legenda', () {
    final s = lookupS(const Locale('pt'));

    test('sem data', () {
      expect(Aluno360FollowUpCard.legenda(s, _hugo()), 'Nenhum retorno agendado');
    });

    test('agendado e último contato', () {
      final a = Aluno(
        id: 1,
        nome: 'Hugo',
        email: 'h@x.com',
        status: 'ATIVO',
        proximoContato: '2026-11-12',
        ultimoContato: '2026-11-02',
      );
      final legenda = Aluno360FollowUpCard.legenda(s, a);
      expect(legenda, startsWith('Agendado para '));
      expect(legenda, contains('Último contato: '));
    });
  });
}
