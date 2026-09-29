import 'package:dio/dio.dart';

import '../../../core/api/transient_error.dart';

/// Falha do verify que pode se resolver sozinha: qualquer erro sem resposta
/// do servidor (exceto cancelamento pelo app) ou [isTransientApiError].
bool iapVerifyFailureIsTransient(Object error) {
  if (error is DioException &&
      error.response == null &&
      error.type != DioExceptionType.cancel) {
    return true;
  }
  return isTransientApiError(error);
}

/// Conclui a transação depois de um verify que falhou?
///
/// - Android: sempre — o `completePurchase` faz o acknowledge; sem ele a Play
///   reembolsa a compra.
/// - iOS + falha transitória ([iapVerifyFailureIsTransient]): não — o
///   StoreKit reentrega a transação na próxima abertura.
/// - iOS + recusa definitiva (4xx, inclusive 403 de não-dono): sim — evita
///   reentrega em loop.
bool iapShouldCompleteAfterVerifyFailure({
  required Object error,
  required bool isAndroid,
}) => isAndroid || !iapVerifyFailureIsTransient(error);
