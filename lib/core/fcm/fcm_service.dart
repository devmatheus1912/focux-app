import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../api/api_client.dart';
import '../router/app_router.dart';
import '../storage/secure_storage.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: notificação aparece automaticamente. Aqui só chega quando o app está
  // em background; o deep link é processado em [_handleNotificationTap]
  // quando o usuário abrir a notificação.
}

class FcmService {
  static Future<void> init(ApiClient apiClient) async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final token = await messaging.getToken();
    if (token != null) {
      await _registrarToken(token, apiClient);
    }
    messaging.onTokenRefresh.listen((newToken) => _registrarToken(newToken, apiClient));

    // Mensagem em foreground: notificação automática + deep link no tap manual.
    FirebaseMessaging.onMessage.listen((message) {
      // O Android exibe automaticamente; iOS depende de configurar o
      // payload com `notification`. Logging só para diagnóstico.
      if (kDebugMode) debugPrint('[FCM] foreground: ${message.messageId}');
    });

    // Tap em notificação enquanto o app estava em background.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // App foi aberto a partir de uma notificação (terminated state).
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleNotificationTap(initial);
    }
  }

  /// Inscreve-se em tópicos correspondentes ao papel do usuário no
  /// tenant. Chame após o login com `tenantId` resolvido para que
  /// notificações por broadcast (alertas globais por personal/aluno)
  /// cheguem nos dispositivos certos.
  static Future<void> subscribeTenantTopics({
    required int tenantId,
    int? alunoId,
    String? role,
  }) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.subscribeToTopic('tenant_$tenantId');
      if (alunoId != null) {
        await messaging.subscribeToTopic('aluno_$alunoId');
      }
      if (role != null && role.isNotEmpty) {
        await messaging.subscribeToTopic('role_${role.toLowerCase()}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] subscribe topics error: $e');
    }
  }

  static Future<void> unsubscribeTenantTopics({
    required int tenantId,
    int? alunoId,
    String? role,
  }) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.unsubscribeFromTopic('tenant_$tenantId');
      if (alunoId != null) {
        await messaging.unsubscribeFromTopic('aluno_$alunoId');
      }
      if (role != null && role.isNotEmpty) {
        await messaging.unsubscribeFromTopic('role_${role.toLowerCase()}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] unsubscribe topics error: $e');
    }
  }

  /// Roteia o usuário com base no payload `data` da notificação. Suporta:
  /// - `route: "/alunos/123"` → empilha rota literal.
  /// - `alunoId: "123"` → vai para `/alunos/123`.
  /// - `chatId: "123"` → vai para `/alunos/123/chat`.
  static void _handleNotificationTap(RemoteMessage message) {
    try {
      final data = message.data;
      String? route = data['route'] as String?;
      if (route == null || route.isEmpty) {
        final alunoId = data['alunoId'] as String?;
        final chatId = data['chatId'] as String?;
        if (chatId != null && chatId.isNotEmpty) {
          route = '/alunos/$chatId/chat';
        } else if (alunoId != null && alunoId.isNotEmpty) {
          route = '/alunos/$alunoId';
        }
      }
      if (route == null || route.isEmpty) return;
      // Apenas rotas internas: rejeita absolutas (proteção contra phishing
      // através de notificações com URL externa).
      if (!route.startsWith('/')) return;
      AppRouter.router.push(route);
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] tap handler error: $e');
    }
  }

  static Future<void> _registrarToken(String token, ApiClient apiClient) async {
    try {
      final jwtToken = await SecureStorage.getToken();
      if (jwtToken == null) return;
      await apiClient.dio.post('/api/fcm/token', data: {'token': token});
    } catch (e) {
      debugPrint('[Focux] FCM register error: $e');
    }
  }
}
