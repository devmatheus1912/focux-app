import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_view.dart';
import 'package:focux_app/features/dashboard/utils/aluno_perfil_completion.dart';
import 'package:focux_app/features/dashboard/utils/aluno_pendencias.dart';
import 'package:focux_app/features/dashboard/utils/aluno_today_action.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_ferramentas_catalogo.dart';
import 'package:focux_app/features/dashboard/widgets/perfil_aluno_completar_card.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/l10n/app_localizations.dart';

Aluno _aluno({
  String? objetivo,
  String? whatsapp,
  double? peso,
  double? altura,
  String? nascimento,
}) => Aluno(
  id: 1,
  nome: 'Ana',
  email: 'ana@x.com',
  status: 'ATIVO',
  objetivo: objetivo,
  whatsapp: whatsapp,
  peso: peso,
  altura: altura,
  dataNascimento: nascimento,
);

void main() {
  final s = lookupS(const Locale('pt'));

  test('tela Ferramentas do aluno: rota, ajuda, plano e sem o que o dock abre', () {
    final tela = File(
      'lib/features/dashboard/screens/aluno_ferramentas_screen.dart',
    ).readAsStringSync();
    expect(tela, contains('fxScreenA11yScope'));
    expect(tela, contains('FxShellScaffold'));
    expect(tela, contains('FxHelpIconButton'));
    expect(tela, contains('ferramentaLiberada'));
    expect(tela, contains('alunoDashboardHomeProvider'));
    expect(tela, contains('FxErrorState'));
    expect(alunoFerramentasRoute, '/aluno/ferramentas');
    expect(
      File('lib/core/router/app_router_aluno_routes.dart').readAsStringSync(),
      contains("path: '/aluno/ferramentas'"),
    );
  });

  group('ferramentasDoAluno', () {
    test('some o que a barra de baixo já abre', () {
      final rotas = ferramentasDoAluno(s, (_) => true).map((t) => t.route);
      for (final dock in ['/checkin/treinos', '/chat/aluno', '/saude']) {
        expect(rotas, isNot(contains(dock)));
      }
      expect(rotas, containsAll(['/agenda/aluno', '/aluno/habitos', '/financeiro/aluno']));
    });

    test('some o que o plano bloqueia', () {
      final rotas = ferramentasDoAluno(
        s,
        (r) => r != '/aluno/desafios',
      ).map((t) => t.route);
      expect(rotas, isNot(contains('/aluno/desafios')));
      expect(rotas, contains('/aluno/habitos'));
    });
  });

  group('queFaltaNoPerfil', () {
    test('lista o que falta, na ordem da tela', () {
      expect(queFaltaNoPerfil(s, _aluno()), 'contato, objetivo e dados corporais');
    });

    test('no máximo três itens', () {
      expect(queFaltaNoPerfil(s, _aluno()).split(RegExp(r',| e ')), hasLength(3));
    });

    test('um item só', () {
      expect(
        queFaltaNoPerfil(
          s,
          _aluno(
            objetivo: 'Hipertrofia',
            whatsapp: '11999999999',
            peso: 70,
            altura: 1.7,
          ),
        ),
        'nascimento',
      );
    });

    test('nada falta: vazio', () {
      expect(
        queFaltaNoPerfil(
          s,
          _aluno(
            objetivo: 'x',
            whatsapp: '1',
            peso: 70,
            altura: 1.7,
            nascimento: '1990-01-01',
          ),
        ),
        '',
      );
    });
  });

  group('próximos passos além das três visíveis', () {
    const abertas = [
      AlunoPendencia(AlunoPendenciaTipo.chat, quantidade: 1),
      AlunoPendencia(AlunoPendenciaTipo.medida),
      AlunoPendencia(AlunoPendenciaTipo.perfil),
      AlunoPendencia(AlunoPendenciaTipo.agenda),
    ];

    test('visíveis cortam em três e o resto sobra para "Ver mais"', () {
      final naHome = alunoPendenciasNaHome(abertas, AlunoTodayMode.workoutReady);
      expect(naHome, hasLength(4));
      expect(
        alunoPendenciasVisiveis(abertas, AlunoTodayMode.workoutReady),
        hasLength(alunoPendenciasMax),
      );
      expect(naHome.skip(alunoPendenciasMax), hasLength(1));
    });

    test('sem treino, o chat não entra (o foco já leva ao chat)', () {
      final naHome = alunoPendenciasNaHome(abertas, AlunoTodayMode.noWorkout);
      expect(naHome.map((p) => p.tipo), isNot(contains(AlunoPendenciaTipo.chat)));
    });
  });

  group('PerfilAlunoCompletarCard', () {
    Future<void> abrir(WidgetTester tester, int score, VoidCallback onTap) =>
        tester.pumpWidget(
          MaterialApp(
            locale: const Locale('pt'),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: S.localizationsDelegates,
            home: Scaffold(
              body: PerfilAlunoCompletarCard(
                score: score,
                queFalta: 'contato e objetivo',
                onTap: onTap,
              ),
            ),
          ),
        );

    testWidgets('mostra progresso, o que falta e abre o cadastro', (tester) async {
      var toques = 0;
      await abrir(tester, 57, () => toques++);
      expect(find.text('Completar cadastro'), findsOneWidget);
      expect(find.textContaining('57% completo'), findsOneWidget);
      expect(find.textContaining('Falta: contato e objetivo'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Completar'));
      expect(toques, 1);
    });

    testWidgets('em 100% não existe', (tester) async {
      await abrir(tester, 100, () {});
      expect(find.text('Completar cadastro'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });
}
