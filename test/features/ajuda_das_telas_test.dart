import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/widgets/add_aluno_help_sheet.dart';
import 'package:focux_app/features/alunos/widgets/alunos_list_help_sheet.dart';
import 'package:focux_app/features/ferramentas/widgets/ferramentas_help_sheet.dart';
import 'package:focux_app/features/treinos/widgets/ficha_help_sheets.dart';
import 'package:focux_app/features/treinos/widgets/treino_detail_help_sheet.dart';
import 'package:focux_app/features/treinos/widgets/treinos_list_help_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _abrir(
  WidgetTester tester,
  Future<void> Function(BuildContext) abre,
) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.binding.setSurfaceSize(const Size(430, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => abre(context),
            child: const Text('abrir ajuda'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir ajuda'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

String _fonte(String caminho) => File(caminho).readAsStringSync();

void main() {
  group('toda tela mexida tem o ícone de ajuda', () {
    const telas = {
      'Hoje': 'lib/features/dashboard/screens/personal_dashboard_screen_build.part.dart',
      'Ficha do aluno': 'lib/features/treinos/screens/aluno_rotina_screen.dart',
      'Modelo': 'lib/features/treinos/screens/ficha_modelo_screen.dart',
      'Fichas anteriores': 'lib/features/treinos/screens/fichas_anteriores_screen.dart',
      'Ferramentas': 'lib/features/ferramentas/screens/ferramentas_screen.dart',
      'Modelos de treino': 'lib/features/treinos/screens/modelos_de_treino_view.dart',
      'Treino': 'lib/features/treinos/screens/treino_detail_screen.dart',
      'Lista de alunos': 'lib/features/alunos/screens/alunos_list_screen_state.part.dart',
      'Novo aluno': 'lib/features/alunos/screens/add_aluno_screen.dart',
      'Editar aluno': 'lib/features/alunos/screens/editar_aluno_screen.dart',
      'Perfil': 'lib/features/perfil/screens/perfil_screen_widgets_a.part.dart',
      'Migração': 'lib/features/growth/screens/migracao_magica_screen_state.part.dart',
      'Hoje do aluno': 'lib/features/dashboard/screens/aluno_dashboard_screen.dart',
      'Treinos do aluno': 'lib/features/checkin/widgets/treinos_hoje_acao.dart',
      'Perfil do aluno': 'lib/features/dashboard/screens/perfil_aluno_screen.dart',
      'Ferramentas do aluno': 'lib/features/dashboard/screens/aluno_ferramentas_screen.dart',
    };
    for (final e in telas.entries) {
      test(e.key, () {
        final fonte = _fonte(e.value);
        expect(
          fonte.contains('FxHelpIconButton') || fonte.contains('onHelp'),
          isTrue,
          reason: '${e.key} precisa de ajuda (${e.value})',
        );
      });
    }
  });

  group('o texto não fala do que saiu', () {
    final todos = [
      'lib/features/dashboard/utils/dashboard_microcopy.dart',
      'lib/features/dashboard/widgets/dashboard_home_help_sheet.dart',
      'lib/features/alunos/widgets/alunos_list_help_sheet.dart',
      'lib/features/alunos/widgets/add_aluno_help_sheet.dart',
      'lib/features/alunos/widgets/editar_aluno_help_sheet.dart',
      'lib/features/treinos/widgets/treinos_list_help_sheet.dart',
      'lib/features/treinos/widgets/treino_detail_help_sheet.dart',
      'lib/features/treinos/widgets/ficha_help_sheets.dart',
      'lib/features/ferramentas/widgets/ferramentas_help_sheet.dart',
      'lib/features/perfil/screens/perfil_screen_widgets_a.part.dart',
      'lib/features/growth/screens/migracao_magica_screen_state.part.dart',
    ].map(_fonte).join('\n');

    test('sem banner de contato, chip Foco, radar do Hoje, Vitrine, OCR e Perfil inicial', () {
      for (final velho in [
        'O banner só aparece',
        'chip Foco',
        'Radar e pulso',
        'Busca e catálogo',
        'Foco do dia',
        'Biblioteca de treinos',
        'OCR gratuito',
        "'Vitrine'",
        "'Perfil inicial'",
        'Mais ferramentas abre o catálogo',
      ]) {
        expect(todos.contains(velho), isFalse, reason: 'ainda cita: $velho');
      }
    });

    test('cita o que existe agora', () {
      for (final novo in [
        'Agora',
        'A base',
        'Fichas anteriores',
        'Sua página',
        'Preferências',
        'Ainda não entrou',
        'Semanas e Sessões',
      ]) {
        expect(todos.contains(novo), isTrue, reason: 'falta citar: $novo');
      }
    });
  });

  group('as folhas abrem com título e dicas', () {
    testWidgets('Ficha do aluno', (tester) async {
      await _abrir(tester, showFichaHelpSheet);
      expect(find.text('Ficha do aluno'), findsOneWidget);
      expect(find.text('Vale por'), findsOneWidget);
      expect(find.text('Fichas anteriores'), findsOneWidget);
      expect(find.text('Recomeçar'), findsOneWidget);
    });

    testWidgets('Modelo de ficha', (tester) async {
      await _abrir(tester, showModeloHelpSheet);
      expect(find.text('Modelo de ficha'), findsOneWidget);
      expect(find.text('Aplicar em aluno'), findsOneWidget);
      expect(find.text('Cópia, não vínculo'), findsOneWidget);
    });

    testWidgets('Fichas anteriores', (tester) async {
      await _abrir(tester, showFichasAnterioresHelpSheet);
      expect(find.text('Usar como base'), findsOneWidget);
      expect(find.text('Até 12 fichas'), findsOneWidget);
    });

    testWidgets('Ferramentas', (tester) async {
      await _abrir(tester, showFerramentasHelpSheet);
      expect(find.text('Ferramentas'), findsOneWidget);
      expect(find.text('Plano'), findsOneWidget);
    });

    testWidgets('Modelos de treino', (tester) async {
      await _abrir(tester, showTreinosListHelpSheet);
      expect(find.text('Modelos de treino'), findsOneWidget);
      expect(find.text('Novo modelo'), findsOneWidget);
    });

    testWidgets('Treino', (tester) async {
      await _abrir(tester, showTreinoDetailHelpSheet);
      expect(find.text('De onde vem'), findsOneWidget);
    });

    testWidgets('Lista de alunos', (tester) async {
      await _abrir(tester, showAlunosListHelpSheet);
      expect(find.text('Filtros'), findsOneWidget);
      expect(find.text('Convite pendente'), findsOneWidget);
      expect(find.text('Novo aluno e importar'), findsOneWidget);
    });

    testWidgets('Novo aluno', (tester) async {
      await _abrir(tester, showAddAlunoHelpSheet);
      expect(find.text('Sobre o aluno'), findsOneWidget);
      expect(find.text('Perfil inicial'), findsNothing);
    });
  });
}
