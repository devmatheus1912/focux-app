import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_series_pendentes.dart';
import 'package:focux_app/features/checkin/widgets/checkin_execucao_estados.dart';
import 'package:focux_app/features/checkin/widgets/checkin_media_widgets.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/checkin_screen_harness.dart';

/// Haptics de sucesso (`selectionClick`) vistos pelo canal da plataforma.
List<String> _gravarHaptics(WidgetTester tester) {
  final tipos = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') {
      tipos.add('${call.arguments}');
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return tipos;
}

const _sucesso = 'HapticFeedbackType.selectionClick';

void main() {
  const fila = CheckinSeriesPendentesStore();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Registrar na zona do polegar', () {
    testWidgets('Registrar fica no rodapé fixo, fora do scroll', (
      tester,
    ) async {
      await pumpCheckin(tester, FakeCheckinRepo());

      final registrar = find.text('Registrar série');
      expect(registrar, findsOneWidget);
      expect(
        find.ancestor(of: registrar, matching: find.byType(CheckinRodapeBar)),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: registrar,
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 1));
      final rodape = tester.getRect(find.byType(CheckinRodapeBar));
      expect(rodape.bottom, closeTo(1400, 1));
      expect(rodape.height, greaterThanOrEqualTo(48));
    });

    testWidgets('Finalizar incompleto sai do rodapé e vira texto no conteúdo', (
      tester,
    ) async {
      await pumpCheckin(tester, FakeCheckinRepo());

      final finalizar = find.text('Finalizar treino');
      expect(
        find.ancestor(of: finalizar, matching: find.byType(CheckinRodapeBar)),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: finalizar,
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byType(CheckinFinalizarLink)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('tudo feito: Finalizar ocupa o rodapé', (tester) async {
      await pumpCheckin(tester, FakeCheckinRepo(feitas: [3, 3]));

      expect(
        find.ancestor(
          of: find.text('Finalizar treino'),
          matching: find.byType(CheckinRodapeBar),
        ),
        findsOneWidget,
      );
      expect(find.text('Registrar série'), findsNothing);
    });

    testWidgets('descanso não mostra Registrar no rodapé', (tester) async {
      await pumpCheckin(tester, FakeCheckinRepo());
      await tocarRegistrar(tester);

      expect(find.text('Pular descanso'), findsOneWidget);
      expect(find.byType(CheckinRodapeBar), findsNothing);
    });
  });

  group('salvar série com garantia', () {
    testWidgets(
      'botão mostra Salvando…, ignora 2º toque e só vibra após a resposta',
      (tester) async {
        final repo = FakeCheckinRepo()..travaSerie = Completer<void>();
        await pumpCheckin(tester, repo);
        final haptics = _gravarHaptics(tester);

        await tester.tap(find.text('Registrar série'));
        await tester.pump();

        expect(find.text('Salvando…'), findsOneWidget);
        expect(haptics, isNot(contains(_sucesso)));
        await tester.tap(find.text('Salvando…'), warnIfMissed: false);
        await tester.pump();
        expect(repo.registros, 1);

        repo.travaSerie!.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(haptics, contains(_sucesso));
        expect(find.text('Pular descanso'), findsOneWidget);
        expect(repo.registros, 1);
      },
    );

    for (final (nome, erro) in [
      ('500', checkinErroStatus(500)),
      ('429', checkinErroStatus(429)),
      (
        'timeout',
        DioException(
          requestOptions: RequestOptions(path: '/series'),
          type: DioExceptionType.receiveTimeout,
        ),
      ),
    ]) {
      testWidgets('$nome guarda a série na fila e conta como feita', (
        tester,
      ) async {
        final repo = FakeCheckinRepo()..erroSerie = erro;
        await pumpCheckin(tester, repo);
        final haptics = _gravarHaptics(tester);

        await tocarRegistrar(tester);

        expect(find.text('1 série esperando conexão'), findsOneWidget);
        expect(find.text('Pular descanso'), findsOneWidget);
        expect((await fila.ler()).single.numero, 1);
        expect(haptics, contains(_sucesso));
      });
    }

    testWidgets('400 mostra erro humano, não enfileira e mantém o digitado', (
      tester,
    ) async {
      final repo =
          FakeCheckinRepo()
            ..erroSerie = checkinErroStatus(
              400,
              erro: 'Número da série acima do planejado.',
            );
      await pumpCheckin(tester, repo);
      final haptics = _gravarHaptics(tester);

      await tester.tap(find.byTooltip('Aumentar kg'));
      await tester.pump();
      await tocarRegistrar(tester);

      expect(find.text('Número da série acima do planejado.'), findsOneWidget);
      expect(find.text('Pular descanso'), findsNothing);
      expect(find.text('0/3'), findsOneWidget);
      expect(await fila.ler(), isEmpty);
      expect(haptics, isNot(contains(_sucesso)));

      repo.erroSerie = null;
      await tocarRegistrar(tester);
      expect(repo.cargas, [22.5, 22.5]);
      expect(find.text('Pular descanso'), findsOneWidget);
    });

    testWidgets('401 com sessão encerrada: nada no aparelho, sem vibração', (
      tester,
    ) async {
      final repo = FakeCheckinRepo()..erroSerie = checkinErroStatus(401);
      final h = await pumpCheckin(tester, repo);
      h.sessaoAtiva = false;
      final haptics = _gravarHaptics(tester);

      await tocarRegistrar(tester);

      expect(await fila.ler(), isEmpty);
      expect(find.text('1 série esperando conexão'), findsNothing);
      expect(find.text('Pular descanso'), findsNothing);
      expect(find.text('0/3'), findsOneWidget);
      expect(haptics, isNot(contains(_sucesso)));
      expect(find.text('Sessão expirada. Faça login novamente.'), findsOneWidget);
    });

    testWidgets('dois toques abrem um só pedido de esforço; cancelar libera', (
      tester,
    ) async {
      final repo = FakeCheckinRepo(rpeAlvo: 8);
      await pumpCheckin(tester, repo);

      await tester.tap(find.text('Registrar série'));
      await tester.tap(find.text('Registrar série'), warnIfMissed: false);
      await pumpSheet(tester);
      expect(find.text('Esforço sentido (RPE)'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await pumpSheet(tester);
      expect(find.text('Esforço sentido (RPE)'), findsNothing);
      expect(repo.registros, 0);
      expect(find.text('Salvando…'), findsNothing);
      expect(find.text('Registrar série'), findsOneWidget);
    });

    testWidgets('pedido de esforço aberto não mostra "Salvando…" atrás', (
      tester,
    ) async {
      final repo = FakeCheckinRepo(rpeAlvo: 8);
      await pumpCheckin(tester, repo);

      await tester.tap(find.text('Registrar série'));
      await pumpSheet(tester);

      expect(find.text('Esforço sentido (RPE)'), findsOneWidget);
      expect(find.text('Salvando…'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(CheckinRodapeBar),
          matching: find.text('Registrar série'),
        ),
        findsOneWidget,
      );
      expect(repo.registros, 0);
    });

    testWidgets('durante o envio, Mais não oferece desfazer nem confirmar', (
      tester,
    ) async {
      final repo =
          FakeCheckinRepo(feitas: [1, 0])..travaSerie = Completer<void>();
      await pumpCheckin(tester, repo);

      await tester.tap(find.text('Próxima série'));
      await tester.pump();
      await tester.tap(find.text('Mais'));
      await pumpSheet(tester);

      expect(find.text('Ajustar'), findsOneWidget);
      expect(find.text('Desfazer série'), findsNothing);
      expect(find.textContaining('Confirmar'), findsNothing);
      repo.travaSerie!.complete();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('erro com série pendente não cobre o "Tentar agora"', (
      tester,
    ) async {
      final repo = FakeCheckinRepo()..offline = true;
      await pumpCheckin(tester, repo);
      await tocarRegistrar(tester);
      await tester.tap(find.text('Pular descanso'));
      await tester.pump();

      repo
        ..offline = false
        ..erroSerie = checkinErroStatus(400, erro: 'Série recusada.');
      await tocarRegistrar(tester, primeira: false);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Série recusada.'), findsOneWidget);
      final superficie = find.descendant(
        of: find.byType(SnackBar),
        matching: find.byType(Material),
      );
      expect(
        tester.getRect(superficie.first).bottom,
        lessThanOrEqualTo(tester.getRect(find.text('Tentar agora')).top),
      );
    });
  });

  group('Descartar com confirmação', () {
    testWidgets('1º toque só abre a confirmação; Voltar mantém o treino', (
      tester,
    ) async {
      final repo = FakeCheckinRepo(feitas: [1, 0]);
      await pumpCheckin(tester, repo);

      await tester.tap(find.text('Sair'));
      await pumpSheet(tester);
      await tester.tap(find.text('Descartar'));
      await pumpSheet(tester);

      expect(find.text('Descartar treino?'), findsOneWidget);
      expect(
        find.text('As séries registradas nesta sessão serão apagadas.'),
        findsOneWidget,
      );
      expect(repo.descartes, 0);

      await tester.tap(find.text('Voltar ao treino'));
      await pumpSheet(tester);
      expect(repo.descartes, 0);
      expect(find.text('treinos'), findsNothing);
      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('2º toque em Descartar apaga e sai', (tester) async {
      final repo = FakeCheckinRepo(feitas: [1, 0]);
      await pumpCheckin(tester, repo);

      await tester.tap(find.text('Sair'));
      await pumpSheet(tester);
      await tester.tap(find.text('Descartar'));
      await pumpSheet(tester);
      await tester.tap(find.text('Descartar'));
      await pumpSheet(tester);

      expect(repo.descartes, 1);
      expect(find.text('treinos'), findsOneWidget);
    });
  });

  group('concluir idempotente', () {
    testWidgets('retry sem evolução mostra o resumo sem inventar recorde', (
      tester,
    ) async {
      final repo = FakeCheckinRepo(feitas: [3, 3])..concluirSemEvolucao = true;
      await pumpCheckin(tester, repo);

      await tester.tap(find.text('Finalizar treino'));
      await pumpSheet(tester);

      expect(find.text('Treino concluído'), findsOneWidget);
      expect(find.text('Recordes de hoje'), findsNothing);
    });

    testWidgets('backend antigo "já foi concluído" segue como sucesso', (
      tester,
    ) async {
      final repo =
          FakeCheckinRepo(feitas: [3, 3])
            ..erroConcluir = checkinErroStatus(
              400,
              erro: 'Este treino já foi concluído.',
            );
      await pumpCheckin(tester, repo);

      await tester.tap(find.text('Finalizar treino'));
      await pumpSheet(tester);

      expect(find.text('Este treino já foi concluído.'), findsNothing);
      expect(find.text('Treino concluído'), findsOneWidget);
      expect(find.text('Recordes de hoje'), findsNothing);
    });

    testWidgets('timeout mostra erro e o 2º toque conclui', (tester) async {
      final repo =
          FakeCheckinRepo(feitas: [3, 3])
            ..erroConcluir = DioException(
              requestOptions: RequestOptions(path: '/concluir'),
              type: DioExceptionType.receiveTimeout,
            );
      await pumpCheckin(tester, repo);

      await tester.tap(find.text('Finalizar treino'));
      await pumpSheet(tester);
      expect(find.text('Conexão lenta. Verifique sua internet.'), findsOneWidget);
      expect(find.text('Treino concluído'), findsNothing);

      repo
        ..erroConcluir = null
        ..concluirSemEvolucao = true;
      await tester.tap(find.text('Finalizar treino'));
      await pumpSheet(tester);
      expect(repo.concluidos, 2);
      expect(find.text('Treino concluído'), findsOneWidget);
    });
  });

  testWidgets('play/pause do vídeo tem 48 dp, tooltip e semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var toques = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Center(
            child: CheckinVideoPlayButton(
              playing: true,
              onTap: () => toques++,
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(CheckinVideoPlayButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(find.byTooltip('Pausar vídeo'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(CheckinVideoPlayButton)),
      matchesSemantics(
        label: 'Pausar vídeo',
        isButton: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.byType(CheckinVideoPlayButton));
    expect(toques, 1);
    handle.dispose();
  });
}
