import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_detail_ferramentas_tab.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/riverpod_seeds.dart';

Override _plano() => seededPlanoFeatures(PlanoFeatures.optimisticEnterprise);

Aluno _aluno({
  int id = 42,
  String? nascimento = '1998-04-12',
  double? altura = 1.65,
  String? objetivo,
  bool inadimplente = false,
  int? aderencia = 0,
  String? whatsapp = '11999999999',
}) => Aluno(
  id: id,
  nome: 'Beatriz Costa',
  email: 'beatriz@test.com',
  status: 'ATIVO',
  dataNascimento: nascimento,
  altura: altura,
  objetivo: objetivo,
  inadimplente: inadimplente,
  statusFinanceiro: inadimplente ? 'INADIMPLENTE' : 'EM_DIA',
  aderenciaPercent: aderencia,
  whatsapp: whatsapp,
);

Future<void> _abrir(
  WidgetTester tester,
  Aluno aluno, {
  Aluno360Ferramentas bundle = const Aluno360Ferramentas(),
  double escala = 1,
  Size tamanho = const Size(390, 4200),
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});
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
            child: Aluno360DetailFerramentasTab(
              aluno: aluno,
              alunoId: aluno.id,
              isDark: false,
              primary: const Color(0xFF2563EB),
              perfilCompletion: 90,
              animateEntrance: false,
              onEntrancePlayed: () {},
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/alunos/:id/editar',
        builder: (_, __) => const Scaffold(body: Text('rota editar')),
      ),
      GoRoute(
        path: '/alunos/:id/anamnese',
        builder: (_, __) => const Scaffold(body: Text('rota anamnese')),
      ),
      GoRoute(
        path: '/alunos/:id/equipamentos',
        builder: (_, __) => const Scaffold(body: Text('rota equipamentos')),
      ),
    ],
  );
  addTearDown(router.dispose);
  final overrides = <Override>[
    _plano(),
    aluno360FerramentasBundleProvider(aluno.id).overrideWith((ref) async => bundle),
    alunoAderenciaSemanalProvider(aluno.id).overrideWith((ref) async => []),
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
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _modulos = [
  'Treinos',
  'Equipamentos',
  'Aderência',
  'IA Progresso',
  'Feedback em vídeo',
  'Composição corporal',
  'Plano de sucesso',
  'Trilhas',
  'Engajamento',
  'Anamnese',
  'Chat',
  'Mensalidades',
];

void main() {
  testWidgets('todos os módulos aparecem, em quatro grupos, sem "Mais ferramentas"', (tester) async {
    await _abrir(tester, _aluno());
    for (final m in _modulos) {
      expect(find.text(m), findsOneWidget, reason: m);
    }
    for (final g in ['Treino', 'Acompanhamento', 'Relação', 'Dinheiro']) {
      expect(find.text(g), findsOneWidget, reason: g);
    }
    expect(find.text('Mais ferramentas'), findsNothing);
    expect(find.text('Atalhos do aluno'), findsNothing);
    expect(find.text('Medidas'), findsNothing);
    expect(find.text('Ajuda'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dados do aluno: incompleto abre a aba, com o que falta e Editar cadastro', (tester) async {
    await _abrir(tester, _aluno(nascimento: null, altura: null));
    expect(find.text('Dados do aluno'), findsOneWidget);
    expect(find.text('Informar'), findsWidgets);
    expect(find.text('Editar cadastro'), findsOneWidget);
    final dados = tester.getTopLeft(find.text('Dados do aluno')).dy;
    final treino = tester.getTopLeft(find.text('Treinos')).dy;
    expect(dados, lessThan(treino));
  });

  testWidgets('dados do aluno: completo vai para o fim da aba', (tester) async {
    await _abrir(tester, _aluno(objetivo: 'Hipertrofia'));
    final dados = tester.getTopLeft(find.text('Dados do aluno')).dy;
    final dinheiro = tester.getTopLeft(find.text('Mensalidades')).dy;
    expect(dados, greaterThan(dinheiro));
  });

  testWidgets('uma linha de dados abre o cadastro', (tester) async {
    await _abrir(tester, _aluno(nascimento: null, altura: null));
    await tester.tap(find.text('Altura'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('rota editar'), findsOneWidget);
  });

  testWidgets('mensalidade em atraso sobe o grupo Dinheiro e mostra "Em atraso"', (tester) async {
    await _abrir(
      tester,
      _aluno(objetivo: 'Hipertrofia', inadimplente: true, aderencia: 80),
    );
    final dinheiro = tester.getTopLeft(find.text('Dinheiro')).dy;
    final treino = tester.getTopLeft(find.text('Treino')).dy;
    expect(dinheiro, lessThan(treino));
    expect(find.text('Em atraso'), findsOneWidget);
  });

  testWidgets('composição com gordura de 818% pede confirmação, nunca "OK"', (tester) async {
    await _abrir(
      tester,
      _aluno(),
      bundle: const Aluno360Ferramentas(
        composicaoResumo: Aluno360ComposicaoResumo(
          percGordura: 818.0,
          massaMuscular: 51.0,
        ),
      ),
    );
    expect(find.text('Confirme este valor'), findsOneWidget);
    expect(find.textContaining('818,0'), findsWidgets);
  });

  testWidgets('composição normal mostra OK', (tester) async {
    await _abrir(
      tester,
      _aluno(objetivo: 'Hipertrofia'),
      bundle: const Aluno360Ferramentas(
        composicaoResumo: Aluno360ComposicaoResumo(
          percGordura: 18.4,
          massaMuscular: 52.1,
        ),
      ),
    );
    expect(find.text('Confirme este valor'), findsNothing);
    expect(find.text('Última avaliação registrada'), findsOneWidget);
  });

  testWidgets('aderência sem histórico mostra "—" no lugar de 0%', (tester) async {
    await _abrir(tester, _aluno(aderencia: 0));
    expect(find.text('0%'), findsNothing);
  });

  testWidgets('um módulo abre a sua rota (Equipamentos)', (tester) async {
    await _abrir(tester, _aluno());
    await tester.tap(find.text('Equipamentos'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('rota equipamentos'), findsOneWidget);
  });

  for (final escala in [1.3, 2.0]) {
    testWidgets('texto $escala em tela estreita não estoura', (tester) async {
      await _abrir(
        tester,
        _aluno(nascimento: null),
        escala: escala,
        tamanho: const Size(320, 9000),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
