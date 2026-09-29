import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_series_pendentes.dart';
import 'package:focux_app/features/checkin/utils/checkin_execucao_display.dart';
import 'package:focux_app/features/checkin/widgets/checkin_serie_campos_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/dynamic_type_harness.dart';
import '../support/checkin_screen_harness.dart';

void main() {
  const fila = CheckinSeriesPendentesStore();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final tela in kDynamicTypeTelas) {
    testWidgets('rodapé da execução aguenta ${descreverTela(tela)}', (
      tester,
    ) async {
      usarDynamicTypeMaximo(tester, tela);
      final repo = FakeCheckinRepo()..offline = true;
      await pumpCheckin(tester, repo, tela: tela);
      expect(find.text('Registrar série'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tocarRegistrar(tester);
      expect(find.text('Pular descanso'), findsOneWidget);
      expect(find.text('1 série esperando conexão'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sem conexão: série fica feita, descanso começa, aviso aparece', (
    tester,
  ) async {
    final repo = FakeCheckinRepo()..offline = true;
    await pumpCheckin(tester, repo);

    await tocarRegistrar(tester);

    expect(find.text('Pular descanso'), findsOneWidget);
    expect(find.text('1 série esperando conexão'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('1 série esperando conexão')).style?.fontSize,
      checkinPendentesAvisoFonte,
    );
    expect((await fila.ler()).single.numero, 1);

    await tester.tap(find.text('Pular descanso'));
    await tester.pump();
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('conexão volta: fila reenvia e o aviso some', (tester) async {
    final repo = FakeCheckinRepo()..offline = true;
    final h = await pumpCheckin(tester, repo);
    await tocarRegistrar(tester);
    expect(find.text('1 série esperando conexão'), findsOneWidget);

    repo.offline = false;
    h.conexao.add(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('1 série esperando conexão'), findsNothing);
    expect(await fila.ler(), isEmpty);
    expect(repo.registros, 2);
  });

  testWidgets('"Tentar agora" e voltar do background reenviam', (tester) async {
    final repo = FakeCheckinRepo()..offline = true;
    await pumpCheckin(tester, repo);
    await tocarRegistrar(tester);

    await tester.tap(find.text('Tentar agora'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(repo.registros, 2);
    expect(find.text('1 série esperando conexão'), findsOneWidget);

    repo.offline = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('1 série esperando conexão'), findsNothing);
  });

  testWidgets('abrir a execução reenvia a fila salva no aparelho', (
    tester,
  ) async {
    await fila.adicionar(
      const CheckinSeriePendente(
        execucaoId: 1,
        treinoExercicioId: 2,
        numero: 1,
        cargaKg: 20,
        repeticoes: '10',
      ),
    );
    final repo = FakeCheckinRepo();
    await pumpCheckin(tester, repo);

    expect(repo.registros, 1);
    expect(await fila.ler(), isEmpty);
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('finalizar com série pendente avisa e não conclui', (
    tester,
  ) async {
    final repo = FakeCheckinRepo()..offline = true;
    await pumpCheckin(tester, repo);
    await tocarRegistrar(tester);
    await tester.tap(find.text('Pular descanso'));
    await tester.pump();

    await tester.tap(find.text('Finalizar treino'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text(
        'Conecte-se para enviar as séries pendentes antes de continuar.',
      ),
      findsOneWidget,
    );
    expect(repo.concluidos, 0);
  });

  testWidgets('finalizar incompleto pede confirmação', (tester) async {
    final repo = FakeCheckinRepo();
    await pumpCheckin(tester, repo);

    await tester.tap(find.text('Finalizar treino'));
    await pumpSheet(tester);
    expect(find.text('Faltam 2 exercícios'), findsOneWidget);
    await tester.tap(find.text('Voltar ao treino'));
    await pumpSheet(tester);
    expect(repo.concluidos, 0);

    await tester.tap(find.text('Finalizar treino'));
    await pumpSheet(tester);
    await tester.tap(find.text('Finalizar'));
    await pumpSheet(tester);
    expect(repo.concluidos, 1);

    await tester.tap(find.text('Continuar'));
    await pumpSheet(tester);
    expect(find.text('treinos'), findsOneWidget);
  });

  testWidgets('"Encerrar agora" também confirma quando falta exercício', (
    tester,
  ) async {
    final repo = FakeCheckinRepo(feitas: [3, 1]);
    await pumpCheckin(tester, repo);

    await tester.tap(find.text('Sair'));
    await pumpSheet(tester);
    await tester.tap(find.text('Encerrar agora'));
    await pumpSheet(tester);

    expect(find.text('Falta 1 exercício'), findsOneWidget);
    expect(repo.concluidos, 0);
  });

  testWidgets('tudo feito finaliza sem confirmação', (tester) async {
    final repo = FakeCheckinRepo(feitas: [3, 3]);
    await pumpCheckin(tester, repo);

    await tester.tap(find.text('Finalizar treino'));
    await pumpSheet(tester);

    expect(find.textContaining('Falta'), findsNothing);
    expect(repo.concluidos, 1);
    await tester.tap(find.text('Continuar'));
    await pumpSheet(tester);
  });

  testWidgets('fim do descanso com app aberto toca e volta à série', (
    tester,
  ) async {
    final repo = FakeCheckinRepo();
    final h = await pumpCheckin(tester, repo);
    await tocarRegistrar(tester);
    expect(find.text('Pular descanso'), findsOneWidget);

    h.agora = h.agora.add(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 1));

    expect(h.alerta.toques, 1);
    expect(find.text('Pular descanso'), findsNothing);
    expect(find.text('Próxima série'), findsOneWidget);
  });

  testWidgets('pular ou voltar do background não toca', (tester) async {
    final repo = FakeCheckinRepo();
    final h = await pumpCheckin(tester, repo);
    await tocarRegistrar(tester);
    await tester.tap(find.text('Pular descanso'));
    await tester.pump(const Duration(seconds: 2));
    expect(h.alerta.toques, 0);

    await tocarRegistrar(tester, primeira: false);
    expect(find.text('Pular descanso'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    h.agora = h.agora.add(const Duration(seconds: 61));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));

    expect(h.alerta.toques, 0);
    expect(find.text('Pular descanso'), findsNothing);
  });

  testWidgets('chip de sensação tem 48 dp de alvo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CheckinFeedbackChip(
              label: 'Ok',
              selected: false,
              color: Colors.teal,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(CheckinFeedbackChip));
    expect(size.height, greaterThanOrEqualTo(checkinFeedbackChipMin));
    expect(size.width, greaterThanOrEqualTo(checkinFeedbackChipMin));
  });
}
