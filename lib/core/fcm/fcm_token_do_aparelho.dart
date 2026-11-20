import 'dart:async';

/// Busca o token do FCM sem engolir a falha.
///
/// No iOS o Firebase só gera o token depois que o sistema entrega o token
/// APNs, o que pode levar alguns segundos depois da abertura ou da permissão.
/// Pedir antes lança `apns-token-not-set`, e o `onTokenRefresh` não volta a
/// disparar: o aparelho ficava sem push para sempre. Por isso [apns] é
/// consultado até [tentativas] vezes antes de pedir o token.
///
/// Toda falha chama [avisar] com o motivo (código do erro, nunca o token),
/// para o registro não voltar a falhar em silêncio.
Future<String?> obterTokenFcm({
  required Future<String?> Function() fcm,
  required void Function(String motivo) avisar,
  Future<String?> Function()? apns,
  int tentativas = 10,
  Duration intervalo = const Duration(seconds: 1),
}) async {
  if (apns != null) {
    String? tokenApns;
    for (var i = 0; i < tentativas; i++) {
      try {
        tokenApns = await apns();
      } catch (_) {
        tokenApns = null;
      }
      if (tokenApns != null) break;
      if (i < tentativas - 1) await Future<void>.delayed(intervalo);
    }
    if (tokenApns == null) {
      avisar('sem token APNs');
      return null;
    }
  }
  try {
    final token = await fcm();
    if (token == null || token.isEmpty) {
      avisar('token FCM vazio');
      return null;
    }
    return token;
  } catch (e) {
    avisar('getToken: ${motivoDoErro(e)}');
    return null;
  }
}

/// Código e mensagem curta do erro, sem nada do aparelho ou da conta.
String motivoDoErro(Object e) {
  final texto = e.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  return texto.length <= 160 ? texto : '${texto.substring(0, 160)}…';
}
