import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../api/api_client.dart';
import '../storage/secure_storage.dart';

// Handler de mensagens em background (top-level function obrigatório pelo Firebase)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // sem-op — notificação já aparece automaticamente no Android/iOS
}

class FcmService {
  static Future<void> init(ApiClient apiClient) async {
    final messaging = FirebaseMessaging.instance;

    // Solicitar permissão (iOS)
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Handler background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Obter token e registrar no backend
    final token = await messaging.getToken();
    if (token != null) {
      await _registrarToken(token, apiClient);
    }

    // Renovação automática do token
    messaging.onTokenRefresh.listen((newToken) => _registrarToken(newToken, apiClient));
  }

  static Future<void> _registrarToken(String token, ApiClient apiClient) async {
    try {
      final jwtToken = await SecureStorage.getToken();
      if (jwtToken == null) return; // usuário não autenticado
      await apiClient.dio.post('/api/fcm/token', data: {'token': token});
    } catch (e) { debugPrint('[Focux] Error: $e');
      // silencioso — não quebrar o app por falha de FCM
    }
  }
}
