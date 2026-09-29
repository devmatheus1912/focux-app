import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/offline_queued_ack.dart';
import 'package:focux_app/core/utils/friendly_error.dart';

Response<dynamic> _response(int status, Object? data) => Response(
  requestOptions: RequestOptions(path: '/api/agenda/1'),
  statusCode: status,
  data: data,
);

void main() {
  test('envelope da fila é reconhecido', () {
    expect(isQueuedOfflineBody(offlineQueuedAckBody()), isTrue);
    expect(isQueuedOffline(_response(202, offlineQueuedAckBody())), isTrue);
  });

  test('entidade real com status "queued" não é envelope', () {
    expect(isQueuedOfflineBody({'id': 3, 'status': 'queued'}), isFalse);
    expect(
      isQueuedOfflineBody({'status': 'queued', 'paymentId': null}),
      isFalse,
    );
  });

  test('só 202 com o envelope conta como enfileirado', () {
    expect(isQueuedOffline(_response(200, offlineQueuedAckBody())), isFalse);
    expect(isQueuedOffline(_response(202, null)), isFalse);
    expect(isQueuedOffline(_response(202, 'queued')), isFalse);
    expect(isQueuedOffline(_response(204, null)), isFalse);
  });

  test('throwIfQueuedOffline lança só para o envelope', () {
    expect(
      () => throwIfQueuedOffline(_response(202, offlineQueuedAckBody())),
      throwsA(isA<OfflineQueuedException>()),
    );
    throwIfQueuedOffline(_response(204, null));
    throwIfQueuedOffline(_response(200, {'id': 1}));
  });

  test('friendlyError não chama ação na fila de erro', () {
    expect(
      friendlyError(const OfflineQueuedException(), fallback: 'Erro ao salvar.'),
      'Sem conexão. Vamos enviar quando a rede voltar.',
    );
  });
}
