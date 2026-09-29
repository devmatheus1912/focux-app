import 'package:dio/dio.dart';

const _queuedStatus = 'queued';
const _ackKeys = {'status', 'message'};

/// Corpo do `202` que o [ApiClient] devolve quando a mutação foi para a fila
/// offline em vez de chegar ao servidor.
Map<String, dynamic> offlineQueuedAckBody() => {
  'status': _queuedStatus,
  'message': 'Offline. Sincronizará quando houver rede.',
};

/// Envelope da fila offline — não é entidade do servidor, mesmo que uma
/// entidade real também tenha `status`.
bool isQueuedOfflineBody(Object? data) {
  if (data is! Map) return false;
  if (data['status']?.toString() != _queuedStatus) return false;
  return data.keys.every((k) => _ackKeys.contains(k.toString()));
}

/// A mutação não chegou ao servidor: só entrou na fila offline.
bool isQueuedOffline(Response<dynamic> response) =>
    response.statusCode == 202 && isQueuedOfflineBody(response.data);

/// A ação foi aceita só localmente e sobe quando a rede voltar. Quem chama
/// não pode mostrar sucesso definitivo nem tratar como falha a refazer.
class OfflineQueuedException implements Exception {
  const OfflineQueuedException();

  @override
  String toString() => 'OfflineQueuedException';
}

/// Lança [OfflineQueuedException] quando [response] é o envelope da fila.
void throwIfQueuedOffline(Response<dynamic> response) {
  if (isQueuedOffline(response)) throw const OfflineQueuedException();
}
