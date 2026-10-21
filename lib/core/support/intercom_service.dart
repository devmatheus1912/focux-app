import 'package:flutter/foundation.dart';
import 'package:intercom_flutter/intercom_flutter.dart';

import 'intercom_config.dart';

/// Wrapper fino sobre o SDK Intercom (v3.x — API estática).
/// Todas as chamadas são no-op em web.
class IntercomService {
  IntercomService._();

  static Future<void> init() async {
    if (kIsWeb) return;
    await Intercom.initialize(
      IntercomConfig.appId,
      iosApiKey: IntercomConfig.iosApiKey,
      androidApiKey: IntercomConfig.androidApiKey,
    );
  }

  /// Identifica o usuário logado no Intercom (personal ou aluno).
  static Future<void> loginUser({
    required String userId,
    String? email,
    String? name,
  }) async {
    if (kIsWeb) return;
    await Intercom.registerIdentifiedUser(userId: userId);
    if (email != null || name != null) {
      await Intercom.updateUser(email: email, name: name);
    }
  }

  /// Chama no logout do app.
  static Future<void> logout() async {
    if (kIsWeb) return;
    await Intercom.logout();
  }

  /// Abre o Messenger como overlay (sem sair do app).
  static Future<void> openMessenger() async {
    if (kIsWeb) return;
    await Intercom.displayMessenger();
  }
}
