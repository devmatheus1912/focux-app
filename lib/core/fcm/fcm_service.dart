import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../api/api_client.dart';
import '../router/app_router.dart';
import '../storage/secure_storage.dart';
import 'fcm_tap_route.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data['type'] == 'plan_sync') {
    // Sem ProviderContainer em background: invalidação ocorre no próximo open
    // ou via tap (onMessageOpenedApp). Handler registrado só em foreground.
  }
}

typedef PlanSyncHandler = Future<void> Function(Map<String, dynamic> data);

class FcmService {
  /// Chamado quando chega FCM `type=plan_sync` (revogação/atualização de tier).
  static PlanSyncHandler? onPlanSync;

  static Future<void> init(ApiClient apiClient) async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final token = await messaging.getToken();
    if (token != null) {
      await _registrarToken(token, apiClient);
    }
    messaging.onTokenRefresh.listen(
      (newToken) => _registrarToken(newToken, apiClient),
    );

    // Mensagem em foreground: notificação automática + deep link no tap manual.
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) debugPrint('[FCM] foreground: ${message.messageId}');
      unawaited(_dispatchPlanSync(message.data));
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

  /// Roteia o toque via [resolveFcmTapRoute]: `route` explícita, senão
  /// `type` já contratado, senão `alunoId` / `chatId` / `execucaoId`.
  static Future<void> _dispatchPlanSync(Map<String, dynamic> data) async {
    if (data['type'] != 'plan_sync') return;
    final handler = onPlanSync;
    if (handler == null) return;
    try {
      await handler(data);
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] plan_sync handler error: $e');
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    try {
      final data = message.data;
      if (data['type'] == 'plan_sync') {
        unawaited(_dispatchPlanSync(data));
      }
      final route = resolveFcmTapRoute(data);
      if (route == null) return;
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

  /// Desfaz o vínculo do dispositivo com a conta que está saindo.
  ///
  /// Precisa rodar **antes** de o JWT ser apagado, porque o endpoint exige
  /// sessão — daí a chamada viver em `AuthRepository.logout` e não no
  /// `SessionInvalidator`, que já roda com o storage limpo.
  ///
  /// O `deleteToken` local no fim não é redundância: ele derruba o token
  /// mesmo que a chamada ao servidor falhe, o que mantém a garantia de que o
  /// aparelho para de receber push da sessão anterior sem depender de rede.
  /// Nada aqui pode escapar: `FirebaseMessaging.instance` lança quando o
  /// Firebase não foi inicializado (web, ou falha do `initializeApp` no
  /// `main`), e logout precisa concluir de qualquer forma.
  static Future<void> desregistrarToken(Dio dio) async {
    try {
      final messaging = FirebaseMessaging.instance;
      try {
        final jwtToken = await SecureStorage.getToken();
        final token = await messaging.getToken();
        if (jwtToken != null && token != null) {
          await dio.delete(
            '/api/fcm/token',
            data: {'token': token},
            options: Options(
              extra: {'fxNoInvalidate': true, 'fxNoOfflineQueue': true},
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[FCM] unregister error: $e');
      }
      await messaging.deleteToken();
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] deleteToken error: $e');
    }
  }
}
