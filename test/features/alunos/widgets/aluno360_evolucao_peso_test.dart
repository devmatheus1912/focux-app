import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_sparkline.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_detail_evolucao_tab.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_timeline_card.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_weight_activity_card.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _id = 42;

Aluno _aluno({double? peso}) => Aluno(
  id: _id,
  nome: 'Hugo Silva',
  email: 'hugo@x.com',
  status: 'ATIVO',
  peso: peso,
);

Future<void> _abrir(
  WidgetTester tester,
  Widget child, {
  List<double> historico = const [],
  double escala = 1,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.binding.setSurfaceSize(const Size(390, 2400));
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
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/alunos/:id/treinos-list',
        builder: (_, __) => const Scaffold(body: Text('rota treinos')),
      ),
    ],
  );
  addTearDown(router.dispose);
  final overrides = <Override>[
    alunoPesoHistoricoProvider(_id).overrideWith((ref) async => historico),
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

Widget _peso(Aluno aluno) => Aluno360WeightActivityCard(
  aluno: aluno,
  alunoId: _id,
  isDark: false,
  ink: Colors.black,
);

Timeline360Event _evento(
  String tipo,
  String titulo,
  String corpo, {
  String quando = '2026-10-26T03:15:00',
}) => Timeline360Event(
  tipo: tipo,
  titulo: titulo,
  corpo: corpo,
  meta: '',
  ocorridoEm: quando,
  deepLink: '',
  prioridade: 'P2',
);

void main() {
  group('peso: uma fonte só', () {
    testWidgets('avaliação de 458 kg e cadastro vazio: o card mostra o valor e pede confirmação', (tester) async {
      await _abrir(tester, _peso(_aluno()), historico: [458.0]);
      expect(find.text('458,0 kg'), findsOneWidget);
      expect(find.text('—'), findsNothing);
      expect(find.text('Confirme este valor'), findsOneWidget);
    });

    testWidgets('um ponto só: sem gráfico e sem "Estável"', (tester) async {
      await _abrir(tester, _peso(_aluno()), historico: [72.0]);
      expect(find.text('72,0 kg'), findsOneWidget);
      expect(find.text('Estável'), findsNothing);
      expect(find.byType(FxSparkline), findsNothing);
      expect(find.text('Registre outra medida para ver a tendência.'), findsOneWidget);
      expect(find.text('Registrar medida'), findsOneWidget);
    });

    testWidgets('peso só do cadastro diz de onde veio, sem fingir tendência', (tester) async {
      await _abrir(tester, _peso(_aluno(peso: 68.5)));
      expect(find.text('68,5 kg'), findsOneWidget);
      expect(find.text('Do cadastro'), findsOneWidget);
      expect(find.text('Estável'), findsNothing);
      expect(find.byType(FxSparkline), findsNothing);
    });

    testWidgets('duas ou mais medidas desenham o gráfico e a variação', (tester) async {
      await _abrir(tester, _peso(_aluno()), historico: [70.0, 72.0]);
      expect(find.byType(FxSparkline), findsOneWidget);
      expect(find.text('+2,0 kg'), findsOneWidget);
      expect(find.text('Confirme este valor'), findsNothing);
    });

    testWidgets('sem nenhum dado convida a registrar a primeira medida', (tester) async {
      await _abrir(tester, _peso(_aluno()));
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Registrar primeira medida'), findsOneWidget);
    });

    testWidgets('a seção não tem o link "Ajuda"', (tester) async {
      await _abrir(tester, _peso(_aluno()), historico: [70.0, 72.0]);
      expect(find.text('Ajuda'), findsNothing);
    });
  });

  group('linha do tempo', () {
    Widget card(List<Timeline360Event> eventos) => Aluno360TimelineCard(
      aluno: _aluno(),
      timelineApiAsync: AsyncData(eventos),
      isDark: false,
    );

    testWidgets('título "Linha do tempo", sem "360" e sem "Ajuda"', (tester) async {
      await _abrir(tester, card([_evento('RADAR', 'Radar Focux · 27 pts', 'Hugo ainda não completou o mapa corporal.')]));
      expect(find.text('Linha do tempo'), findsOneWidget);
      expect(find.textContaining('360'), findsNothing);
      expect(find.text('Ajuda'), findsNothing);
    });

    testWidgets('"Radar Focux" aparece como "Alerta"', (tester) async {
      await _abrir(tester, card([_evento('RADAR', 'Radar Focux · 27 pts', 'Hugo ainda não completou o mapa corporal.')]));
      expect(find.textContaining('Radar Focux'), findsNothing);
      expect(find.text('Alerta · 27 pts'), findsOneWidget);
    });

    testWidgets('visualização do aluno não aparece; concluído aparece', (tester) async {
      await _abrir(
        tester,
        card([
          _evento('AUTONOMIA', 'Completar perfil base', 'VIEWED', quando: '2026-10-22T12:50:00'),
          _evento('AUTONOMIA', 'Registrar primeira medida', 'COMPLETED', quando: '2026-10-23T10:00:00'),
        ]),
      );
      expect(find.text('Completar perfil base'), findsNothing);
      expect(find.text('Registrar primeira medida'), findsOneWidget);
    });

    testWidgets('medida impossível ganha "Confirme este valor" e vírgula', (tester) async {
      await _abrir(tester, card([_evento('MEDIDA', 'Medida corporal', 'Peso 458.00 kg')]));
      expect(find.textContaining('Peso 458,0 kg'), findsOneWidget);
      expect(find.textContaining('Confirme este valor'), findsOneWidget);
    });

    testWidgets('"Ver todos os N" conta só o que o personal vê', (tester) async {
      await _abrir(
        tester,
        card([
          for (var i = 0; i < 4; i++)
            _evento('CHECKIN', 'Check-in ${i + 1}', 'Treino $i', quando: '2026-10-2${i}T10:00:00'),
          _evento('AUTONOMIA', 'Completar perfil base', 'VIEWED'),
        ]),
      );
      expect(find.text('Ver todos os 4 sinais'), findsOneWidget);
    });
  });

  group('aba Evolução', () {
    testWidgets('"Ajustar treino" é uma linha no fim e leva aos treinos', (tester) async {
      await _abrir(
        tester,
        Aluno360DetailEvolucaoTab(
          aluno: _aluno(),
          alunoId: _id,
          isDark: false,
          ink: Colors.black,
          evolucaoAsync: const AsyncLoading(),
          timeline360Async: const AsyncData([]),
          animateEntrance: false,
          onEntrancePlayed: () {},
        ),
        historico: [70.0, 72.0],
      );
      expect(find.byKey(const ValueKey('aluno360_evolucao_ajustar_treino')), findsOneWidget);
      expect(find.text('Ajustar treino'), findsOneWidget);
      await tester.ensureVisible(find.text('Abrir'));
      await tester.tap(find.text('Abrir'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('rota treinos'), findsOneWidget);
    });

    testWidgets('nenhuma seção tem o link "Ajuda"', (tester) async {
      await _abrir(
        tester,
        Aluno360DetailEvolucaoTab(
          aluno: _aluno(),
          alunoId: _id,
          isDark: false,
          ink: Colors.black,
          evolucaoAsync: const AsyncLoading(),
          timeline360Async: const AsyncData([]),
          animateEntrance: false,
          onEntrancePlayed: () {},
        ),
        historico: [70.0, 72.0],
      );
      expect(find.text('Ajuda'), findsNothing);
    });

    testWidgets('texto 2.0 em tela estreita não estoura', (tester) async {
      await _abrir(
        tester,
        Aluno360DetailEvolucaoTab(
          aluno: _aluno(),
          alunoId: _id,
          isDark: false,
          ink: Colors.black,
          evolucaoAsync: const AsyncLoading(),
          timeline360Async: AsyncData([_evento('RADAR', 'Radar Focux · 27 pts', 'Hugo ainda não completou o mapa corporal.')]),
          animateEntrance: false,
          onEntrancePlayed: () {},
        ),
        historico: [458.0],
        escala: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
