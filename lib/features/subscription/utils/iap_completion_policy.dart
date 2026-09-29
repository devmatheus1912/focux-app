import '../../checkin/utils/checkin_series_fila.dart';

/// Conclui a transação depois de um verify que falhou?
///
/// - Android: sempre — o `completePurchase` faz o acknowledge; sem ele a Play
///   reembolsa a compra.
/// - iOS + falha transitória (sem resposta, timeout, 5xx, 429…): não — o
///   StoreKit reentrega a transação na próxima abertura.
/// - iOS + recusa definitiva (4xx, inclusive 403 de não-dono): sim — evita
///   reentrega em loop.
bool iapShouldCompleteAfterVerifyFailure({
  required Object error,
  required bool isAndroid,
}) => isAndroid || !checkinErroTransitorio(error);
