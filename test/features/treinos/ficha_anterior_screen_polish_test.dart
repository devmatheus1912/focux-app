import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/models/ficha_historico.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ficha_historico_harness.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  test('o motivo desconhecido cai em "histórico" e o JSON vira modelo', () {
    expect(MotivoTroca.parse('RECOMECADA'), MotivoTroca.recomecada);
    expect(MotivoTroca.parse('COPIADA_DE_OUTRO'), MotivoTroca.copiadaDeOutro);
    expect(MotivoTroca.parse('NOVO_MOTIVO'), MotivoTroca.historico);
    final ficha = FichaHistorico.fromJson({
      'id': 4,
      'motivo': 'MODELO',
      'nomeModelo': 'Full body',
      'vigenciaInicio': '2026-08-12',
      'vigenciaFim': '2026-10-07',
      'encerradaEm': '2026-10-07T10:00:00',
      'sessoes': 1,
      'exercicios': 5,
      'itens': [
        {
          'tipo': 'TREINO',
          'treinoId': 9,
          'nome': 'Treino A',
          'diaSemana': 1,
          'exerciciosCount': 5,
          'disponivel': true,
        },
        {'tipo': 'DESCANSO'},
      ],
    });
    expect(ficha.motivo, MotivoTroca.modelo);
    expect(ficha.vigenciaFim, DateTime(2026, 10, 7));
    expect(ficha.sessoesDaSemana, hasLength(1));
    expect(ficha.temSessaoDisponivel, isTrue);
  });

  testWidgets('tocar numa ficha abre a semana como era, só de leitura', (
    tester,
  ) async {
    await abrirHistorico(tester, [fichaRecomecada]);

    await tester.tap(find.text('12/08 a 14/10'));
    await assentar(tester);

    expect(find.text('Ficha anterior'), findsWidgets);
    expect(find.text('Treino A'), findsOneWidget);
    expect(find.text('5 exercícios'), findsOneWidget);
    expect(find.text('Treino B · removida'), findsOneWidget);
    expect(find.byTooltip('Mais ações da sessão'), findsNothing);
    expect(find.text('Montar'), findsNothing);

    await tester.tap(find.text('Treino A'));
    await assentar(tester);
    expect(find.text('montador'), findsNothing);
  });

  testWidgets('usar como base pergunta as cargas, avisa e aplica', (
    tester,
  ) async {
    final repo = await abrirHistorico(tester, [
      fichaRecomecada,
    ], destino: '/alunos/3/fichas-anteriores/7');

    await tester.tap(find.text('Usar como base'));
    await assentar(tester);
    await tester.tap(find.text('Manter as cargas'));
    await assentar(tester);

    expect(find.text('Usar esta ficha como base?'), findsOneWidget);
    await tester.tap(find.text('Usar como base').last);
    await assentar(tester);

    expect(repo.usadas, [(3, 7, true)]);
  });

  testWidgets('cancelar a confirmação não aplica nada', (tester) async {
    final repo = await abrirHistorico(tester, [
      fichaRecomecada,
    ], destino: '/alunos/3/fichas-anteriores/7');

    await tester.tap(find.text('Usar como base'));
    await assentar(tester);
    await tester.tap(find.text('Começar do zero'));
    await assentar(tester);
    await tester.tap(find.text('Cancelar'));
    await assentar(tester);

    expect(repo.usadas, isEmpty);
  });

  testWidgets('ficha sem nenhuma sessão disponível não deixa usar', (
    tester,
  ) async {
    final semTreino = FichaHistorico(
      id: 8,
      motivo: MotivoTroca.recomecada,
      encerradaEm: DateTime(2026, 10, 1),
      sessoes: 1,
      itens: const [
        FichaHistoricoItem(
          descanso: false,
          nome: 'Treino X',
          diaSemana: 1,
          exerciciosCount: 3,
        ),
      ],
    );
    final repo = await abrirHistorico(tester, [
      semTreino,
    ], destino: '/alunos/3/fichas-anteriores/8');

    await tester.tap(find.text('Usar como base'));
    await assentar(tester);

    expect(repo.usadas, isEmpty);
    expect(find.text('Usar esta ficha como base?'), findsNothing);
  });
}
