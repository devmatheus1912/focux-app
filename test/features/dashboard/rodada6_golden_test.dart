@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/widgets/aluno_detail_hero_card.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/widgets/tarefa_row.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/widgets/engajamento_card_aderencia.dart';
import 'package:focux_app/l10n/app_localizations.dart';

import '../../support/tolerant_golden_comparator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  Widget harness(Widget child, {required bool dark}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('pt'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    theme: ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      colorSchemeSeed: const Color(0xFF0D9488),
    ),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 358,
          child: Padding(
            padding: const EdgeInsets.all(TokensStrip.s2),
            child: child,
          ),
        ),
      ),
    ),
  );

  final tarefa = FilaAcaoResumo.fromJson({
    'tipo': 'RISCO',
    'actionKey': 'RISCO_7',
    'titulo': 'Mariana Silva',
    'descricao': 'Abriu 2 vezes e não concluiu',
    'acaoUrl': '/alunos/7',
    'prioridade': 'P1',
    'ctaLabel': 'Responder',
    'alunoId': 7,
  });

  for (final dark in [false, true]) {
    final tema = dark ? 'escuro' : 'claro';

    testWidgets('linha de tarefa ($tema)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 220));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        harness(
          Card(
            child: TarefaRow(
              action: tarefa,
              concluida: false,
              ink: dark ? Colors.white : Colors.black87,
              mute: dark ? Colors.white70 : Colors.black54,
              onOpen: () {},
              onConcluir: () {},
              onMais: () {},
            ),
          ),
          dark: dark,
        ),
      );
      await expectFocuxGolden(find.byType(MaterialApp), 'goldens/tarefa_row_$tema.png');
    });

    testWidgets('card de aderência ($tema)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 260));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        harness(
          const EngajamentoCardAderencia(
            resumo: AderenciaResumo(percent: 75, feitos: 9, previstos: 12),
            aderenciaCadastro: 75,
            frase: 'Treinou 3 vezes nesta semana',
            tendencia: (diferenca: 1, texto: '1 treino a mais que na semana anterior'),
          ),
          dark: dark,
        ),
      );
      await expectFocuxGolden(find.byType(MaterialApp), 'goldens/aderencia_card_$tema.png');
    });

    testWidgets('cabeçalho do 360 com risco ($tema)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 340));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        harness(
          AlunoDetailHeroCard(
            aluno: Aluno(
              id: 7,
              nome: 'Mariana Silva',
              email: 'mariana@test.com',
              status: 'ATIVO',
              objetivo: 'Hipertrofia',
              aderenciaPercent: 42,
              diasSemTreino: 9,
              emRisco: true,
              riscoNivel: 'ALTO',
              contaAtiva: true,
            ),
            isDark: dark,
            primary: const Color(0xFF0D9488),
          ),
          dark: dark,
        ),
      );
      await expectFocuxGolden(find.byType(MaterialApp), 'goldens/hero_360_risco_$tema.png');
    });
  }
}
