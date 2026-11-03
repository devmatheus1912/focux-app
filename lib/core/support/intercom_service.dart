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
