import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:intercom_flutter/intercom_flutter.dart';

import 'intercom_config.dart';

/// Wrapper fino sobre o SDK Intercom (plugin 9.x — API por instância).
/// Todas as chamadas são no-op em web.
class IntercomService {
  IntercomService._();

  static Future<void> init() async {
    if (kIsWeb) return;
    await Intercom.instance.initialize(
      IntercomConfig.appId,
      iosApiKey: IntercomConfig.iosApiKey,
      androidApiKey: IntercomConfig.androidApiKey,
    );
  }

  /// Identifica o usuário logado no Intercom (personal ou aluno).
  ///
  /// [userId] deve ser o JWT subject (`personal:<id>` ou `aluno:<id>`).
  ///
  /// Autenticação do Messenger (Settings → Messenger → Segurança):
  /// - [jwt] (`GET /api/auth/intercom-jwt`) é o método atual e tem prioridade.
  ///   [jwtProvider] devolve um token novo quando o SDK pede (o JWT vale 1h).
  ///
  /// O token precisa ser definido antes de identificar o usuário.
  static Future<void> loginUser({
    required String userId,
    required String papel,
    String? jwt,
    Future<String?> Function()? jwtProvider,
    String? email,
    String? name,
  }) async {
    if (kIsWeb) return;
    final intercom = Intercom.instance;
    if (jwt != null && jwt.isNotEmpty) {
      await intercom.setUserJwt(jwt);
      if (jwtProvider != null) {
        await intercom.setUserJwtProvider(jwtProvider);
      }
    }
    await intercom.loginIdentifiedUser(userId: userId);
    await intercom.updateUser(
      email: email,
      name: name,
      customAttributes: {'papel': papel},
    );
    // O aparelho passa a ser desta pessoa: a resposta do suporte chega por push.
    await enviarTokenPush();
  }

  /// Entrega ao Intercom o token de push do aparelho: APNs no iOS, FCM no
  /// Android (o Intercom manda direto, sem passar pelo backend). Falha é
  /// silenciosa: sem token, a resposta aparece ao abrir o suporte.
  static Future<void> enviarTokenPush({String? tokenFcm}) async {
    if (kIsWeb) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final token =
          defaultTargetPlatform == TargetPlatform.iOS
              ? await messaging.getAPNSToken()
              : (tokenFcm ?? await messaging.getToken());
      if (token == null || token.isEmpty) return;
      await Intercom.instance.sendTokenToIntercom(token);
    } catch (e) {
      if (kDebugMode) debugPrint('[Intercom] token de push: $e');
    }
  }

  /// A notificação veio do Intercom (resposta do suporte)?
  static Future<bool> ehPushDoIntercom(Map<String, dynamic> data) async {
    if (kIsWeb || data.isEmpty) return false;
    try {
      return await Intercom.instance.isIntercomPush(data);
    } catch (_) {
      return false;
    }
  }

  /// Android: o Intercom monta a notificação do push dele (chega pelo
  /// Firebase do app, que é quem recebe as mensagens).
  static Future<void> mostrarPush(Map<String, dynamic> data) async {
    if (kIsWeb) return;
    try {
      await Intercom.instance.handlePush(data);
    } catch (e) {
      if (kDebugMode) debugPrint('[Intercom] push: $e');
    }
  }

  /// Chama no logout do app.
  static Future<void> logout() async {
    if (kIsWeb) return;
    identificar = null;
    final intercom = Intercom.instance;
    await intercom.removeUserJwtProvider();
    await intercom.logout();
  }

  /// Abre o Messenger como overlay (sem sair do app).
  /// Identifica o usuário só ao abrir o suporte, sem chamada a cada início do app.
  static Future<void> Function()? identificar;

  static Future<void> openMessenger() async {
    if (kIsWeb) return;
    await identificar?.call();
    identificar = null;
    await Intercom.instance.displayMessenger();
  }
}
