import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../api/api_client.dart';
import '../api/offline_sync_service.dart';
import '../router/app_router.dart';
import '../storage/secure_storage.dart';
import '../widgets/feedback_helper.dart';
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

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Listeners e mensagem inicial antes de qualquer await que possa falhar:
    // getToken lança sem APNs/rede e o toque que abriu o app se perderia.
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) debugPrint('[FCM] foreground: ${message.messageId}');
      unawaited(_dispatchPlanSync(message.data));
      _avisarEmPrimeiroPlano(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    try {
      final initial = await messaging.getInitialMessage();
      if (initial != null) _handleNotificationTap(initial);
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] initial message error: $e');
    }

    // Permissão só pós-login (requestPermissionIfNeeded); quem já concedeu
    // segue recebendo com o token registrado abaixo.
    try {
      // iOS só mostra banner com o app aberto se pedirmos.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] presentation options error: $e');
    }

    messaging.onTokenRefresh.listen(
      (newToken) => _registrarToken(newToken, apiClient),
    );
    try {
      final token = await messaging.getToken();
      if (token != null) await _registrarToken(token, apiClient);
    } catch (e) {
      // Sem APNs ainda ou offline: onTokenRefresh entrega depois.
      if (kDebugMode) debugPrint('[FCM] getToken error: $e');
    }
  }

  /// Android não exibe notificação com o app aberto; iOS já mostra o banner.
  static void _avisarEmPrimeiroPlano(RemoteMessage message) {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final n = message.notification;
    if (n == null) return;
    final titulo = n.title?.trim() ?? '';
    final corpo = n.body?.trim() ?? '';
    final texto = [titulo, corpo].where((s) => s.isNotEmpty).join(' — ');
    if (texto.isEmpty) return;
    final ctx = AppRouter.router.routerDelegate.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    FeedbackHelper.showInfo(ctx, texto);
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
    unawaited(_handleNotificationTapAsync(message));
  }

  static Future<void> _handleNotificationTapAsync(RemoteMessage message) async {
    try {
      final data = message.data;
      if (data['type'] == 'plan_sync') {
        await _dispatchPlanSync(data);
      }
      final role = await SecureStorage.getRole();
      final route = resolveFcmTapRoute(data, role: role);
      if (route == null) return;
      // Apenas rotas internas: rejeita absolutas (proteção contra phishing
      // através de notificações com URL externa).
      if (!route.startsWith('/')) return;
      if (fcmTapUsaGo(route)) {
        AppRouter.router.go(route);
      } else {
        AppRouter.router.push(route);
      }
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
      if (kDebugMode) debugPrint('[Focux] FCM register error: $e');
    }
  }

  /// Após login — boot pode ter rodado `init` sem JWT.
  static Future<void> registrarSeAutenticado(ApiClient apiClient) async {
    try {
      final jwtToken = await SecureStorage.getToken();
      if (jwtToken == null) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _registrarToken(token, apiClient);
    } catch (e) {
      if (kDebugMode) debugPrint('[Focux] FCM post-login register error: $e');
    }
  }

  static Future<void>? _permissionInFlight;

  /// Pede permissão de notificação (prompt só na primeira vez) e registra o
  /// token. Chamar com sessão ativa — nunca no boot deslogado.
  static Future<void> requestPermissionIfNeeded(ApiClient apiClient) {
    if (kIsWeb) return Future.value();
    return _permissionInFlight ??= _requestPermissionAndRegister(
      apiClient,
    ).whenComplete(() => _permissionInFlight = null);
  }

  static Future<void> _requestPermissionAndRegister(ApiClient apiClient) async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] permission error: $e');
      return;
    }
    await registrarSeAutenticado(apiClient);
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
              extra: {
                'fxNoInvalidate': true,
                OfflineSyncService.noQueueExtra: true,
              },
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
