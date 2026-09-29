import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/chat/data/chat_repository.dart';
import 'package:focux_app/features/chat/utils/chat_outbox.dart';

ChatMsg _msg({
  int? id,
  String clientId = 'c1',
  String conteudo = 'Bora treinar?',
  DateTime? enviadoEm,
  DateTime? deliveredAt,
  DateTime? readAt,
}) => ChatMsg(
  id: id,
  remetente: 'PERSONAL',
  conteudo: conteudo,
  enviadoEm: enviadoEm ?? DateTime(2026, 9, 28, 10),
  tipoMidia: 'TEXTO',
  clientMessageId: clientId,
  deliveredAt: deliveredAt,
  readAt: readAt,
);

void main() {
  group('ChatOutbox', () {
    test('falha mantém a mensagem como não enviada e repassa o erro', () async {
      final outbox = ChatOutbox();
      final optimistic = _msg();
      outbox.track('c1', () async => throw Exception('rede'));

      expect(outbox.statusOf(optimistic), ChatOutgoingStatus.sending);
      await expectLater(outbox.dispatch('c1'), throwsException);

      expect(outbox.isFailed('c1'), isTrue);
      expect(outbox.statusOf(optimistic), ChatOutgoingStatus.failed);
    });

    test('reenvio roda a mesma operação e o sucesso limpa a falha', () async {
      final outbox = ChatOutbox();
      final enviados = <String>[];
      var falhar = true;
      outbox.track('c1', () async {
        enviados.add('c1');
        if (falhar) throw Exception('rede');
        return _msg(id: 42);
      });

      await expectLater(outbox.dispatch('c1'), throwsException);
      falhar = false;
      final confirmada = await outbox.dispatch('c1');

      expect(enviados, ['c1', 'c1']);
      expect(confirmada?.id, 42);
      expect(outbox.isFailed('c1'), isFalse);
      expect(outbox.statusOf(confirmada!), ChatOutgoingStatus.sent);
      expect(await outbox.dispatch('c1'), isNull);
    });

    test('mensagem apagada não volta a falhar nem reenvia', () async {
      final outbox = ChatOutbox();
      var chamadas = 0;
      outbox.track('c1', () async {
        chamadas++;
        throw Exception('rede');
      });
      await expectLater(outbox.dispatch('c1'), throwsException);

      outbox.forget('c1');

      expect(outbox.isFailed('c1'), isFalse);
      expect(await outbox.dispatch('c1'), isNull);
      expect(chamadas, 1);
    });

    test('status do servidor vence: entregue e lido', () {
      final outbox = ChatOutbox();
      final quando = DateTime(2026, 9, 28, 11);
      expect(
        outbox.statusOf(_msg(id: 1, deliveredAt: quando)),
        ChatOutgoingStatus.delivered,
      );
      expect(
        outbox.statusOf(_msg(id: 1, deliveredAt: quando, readAt: quando)),
        ChatOutgoingStatus.read,
      );
    });

    test('mesmo texto digitado de novo acha a bolha não enviada', () async {
      final outbox = ChatOutbox();
      outbox.track('c1', () async => throw Exception('rede'));
      await expectLater(outbox.dispatch('c1'), throwsException);
      final msgs = [_msg(conteudo: 'Bora  treinar?')];

      expect(outbox.failedWithText(msgs, 'bora treinar?'), same(msgs.first));
      expect(outbox.failedWithText(msgs, 'Outra coisa'), isNull);
    });
  });

  group('keepUnsentOutgoing', () {
    test('recarga do histórico preserva a bolha que o servidor não tem', () {
      final servidor = [
        _msg(id: 1, clientId: 's1', enviadoEm: DateTime(2026, 9, 28, 9)),
      ];
      final naoEnviada = _msg(clientId: 'c1');

      final merged = keepUnsentOutgoing(
        server: servidor,
        local: [servidor.first, naoEnviada],
      );

      expect(merged.map((m) => m.clientMessageId), ['s1', 'c1']);
    });

    test('bolha que o servidor já confirmou não duplica', () {
      final confirmada = _msg(id: 7, clientId: 'c1');

      final merged = keepUnsentOutgoing(
        server: [confirmada],
        local: [_msg(clientId: 'c1')],
      );

      expect(merged, [confirmada]);
    });
  });

  group('confirmação tardia', () {
    test('eco do servidor depois da falha encerra a bolha: mesmo texto vira '
        'mensagem nova', () async {
      final outbox = ChatOutbox();
      outbox.track('c1', () async => throw Exception('rede'));
      await expectLater(outbox.dispatch('c1'), throwsException);
      final eco = _msg(id: 5);

      outbox.forgetConfirmed(eco);

      expect(outbox.phaseOf('c1'), ChatSendPhase.gone);
      expect(outbox.failedWithText([eco], 'Bora treinar?'), isNull);
    });

    test('bolha já com id nunca é tratada como não enviada', () async {
      final outbox = ChatOutbox();
      outbox.track('c1', () async => throw Exception('rede'));
      await expectLater(outbox.dispatch('c1'), throwsException);

      expect(outbox.failedWithText([_msg(id: 5)], 'Bora treinar?'), isNull);
    });

    test('WebSocket confirma antes do erro do POST: sem "Não enviada"', () async {
      final outbox = ChatOutbox();
      final resposta = Completer<ChatMsg>();
      outbox.track('c1', () => resposta.future);
      final envio = outbox.dispatch('c1');

      outbox.forgetConfirmed(_msg(id: 5));
      resposta.completeError(Exception('timeout'));

      await expectLater(envio, throwsException);
      expect(outbox.isFailed('c1'), isFalse);
      expect(outbox.phaseOf('c1'), ChatSendPhase.gone);
    });

    test('mensagem sem id do servidor não encerra o envio', () {
      final outbox = ChatOutbox();
      outbox.track('c1', () async => _msg(id: 1));

      outbox.forgetConfirmed(_msg());

      expect(outbox.phaseOf('c1'), ChatSendPhase.sending);
    });
  });

  group('409 da idempotência', () {
    DioException conflito() => DioException(
      requestOptions: RequestOptions(path: '/api/chat/aluno/enviar'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/chat/aluno/enviar'),
        statusCode: 409,
      ),
    );

    test('primeira tentativa em processamento segue "Enviando…"', () async {
      final outbox = ChatOutbox();
      final optimistic = _msg();
      outbox.track('c1', () async => throw conflito());

      await expectLater(outbox.dispatch('c1'), throwsA(isA<DioException>()));

      expect(isChatSendInFlight(conflito()), isTrue);
      expect(outbox.phaseOf('c1'), ChatSendPhase.sending);
      expect(outbox.statusOf(optimistic), ChatOutgoingStatus.sending);
    });

    test('409 que não resolve vira "Não enviada" depois do limite', () async {
      final outbox = ChatOutbox();
      outbox.track('c1', () async => throw conflito());

      for (var i = 0; i < chatMaxInFlightChecks; i++) {
        await expectLater(outbox.dispatch('c1'), throwsA(isA<DioException>()));
        expect(outbox.phaseOf('c1'), ChatSendPhase.sending);
      }
      await expectLater(outbox.dispatch('c1'), throwsA(isA<DioException>()));

      expect(outbox.phaseOf('c1'), ChatSendPhase.failed);
    });

    test('outros erros HTTP não contam como em andamento', () {
      final erro = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(requestOptions: RequestOptions(path: '/x'), statusCode: 503),
      );
      expect(isChatSendInFlight(erro), isFalse);
      expect(isChatSendInFlight(Exception('rede')), isFalse);
    });
  });

  test('anexo: reenvio reaproveita a URL do upload e só repete o POST', () async {
    var uploads = 0;
    final urls = <String>[];
    var falhar = true;
    final outbox = ChatOutbox();
    outbox.track(
      'c1',
      chatMediaSendOperation(
        upload: () async {
          uploads++;
          return 'https://cdn.example.test/chat/foto.jpg';
        },
        send: (url) async {
          urls.add(url);
          if (falhar) throw Exception('rede');
          return _msg(id: 3);
        },
      ),
    );

    await expectLater(outbox.dispatch('c1'), throwsException);
    falhar = false;
    await outbox.dispatch('c1');

    expect(uploads, 1);
    expect(urls, hasLength(2));
    expect(urls.toSet(), {'https://cdn.example.test/chat/foto.jpg'});
  });

  test('responder exige mensagem salva e não apagada', () {
    expect(chatCanReplyTo(_msg()), isFalse);
    expect(chatCanReplyTo(_msg(id: 1)), isTrue);
    expect(
      chatCanReplyTo(
        ChatMsg(
          id: 1,
          remetente: 'ALUNO',
          conteudo: '',
          enviadoEm: DateTime(2026, 9, 28),
          deletedAt: DateTime(2026, 9, 28),
        ),
      ),
      isFalse,
    );
  });
}
