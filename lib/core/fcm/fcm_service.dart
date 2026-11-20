import 'dart:async';

import '../versao/atualizacao_scope.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../api/api_client.dart';
import '../api/offline_sync_service.dart';
import '../router/app_router.dart';
import '../storage/secure_storage.dart';
import '../support/intercom_service.dart';
import '../widgets/feedback_helper.dart';
import 'fcm_tap_route.dart';
import 'fcm_token_do_aparelho.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Resposta do suporte com o app fechado (Android): o Intercom mostra.
  if (defaultTargetPlatform == TargetPlatform.android &&
      await IntercomService.ehPushDoIntercom(message.data)) {
    await IntercomService.mostrarPush(message.data);
    return;
  }
  if (message.data['type'] == 'plan_sync') {
    // Sem ProviderContainer em background: invalidação ocorre no próximo open
    // ou via tap (onMessageOpenedApp). Handler registrado só em foreground.
  }
}

typedef PlanSyncHandler = Future<void> Function(Map<String, dynamic> data);

class FcmService {
  /// Chamado quando chega FCM `type=plan_sync` (revogação/atualização de tier).
  static PlanSyncHandler? onPlanSync;

  /// Onde o registro do aparelho está: o teste em Perfil > Notificações
  /// mostra isso quando o push não tem token.
  static String _etapa = 'início não rodou';

  static Future<void> init(ApiClient apiClient) async {
    _etapa = 'iniciando';
    final messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Listeners e mensagem inicial antes de qualquer await que possa falhar:
    // getToken lança sem APNs/rede e o toque que abriu o app se perderia.
    FirebaseMessaging.onMessage.listen((message) async {
      if (kDebugMode) debugPrint('[FCM] foreground: ${message.messageId}');
      if (await IntercomService.ehPushDoIntercom(message.data)) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          await IntercomService.mostrarPush(message.data);
        }
        return;
      }
      unawaited(_dispatchPlanSync(message.data));
      _avisarEmPrimeiroPlano(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    _etapa = 'mensagem inicial';
    try {
      final initial = await messaging.getInitialMessage();
      if (initial != null) _handleNotificationTap(initial);
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] initial message error: $e');
    }

    // Permissão só pós-login (requestPermissionIfNeeded); quem já concedeu
    // segue recebendo com o token registrado abaixo.
    _etapa = 'opções de exibição';
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

    messaging.onTokenRefresh.listen((newToken) {
      unawaited(_registrarToken(newToken, apiClient));
      unawaited(IntercomService.enviarTokenPush(tokenFcm: newToken));
    });
    _etapa = 'pedindo o token';
    final token = await _tokenDoAparelho();
    _etapa = token == null ? 'sem token' : 'token obtido';
    if (token != null) await _registrarToken(token, apiClient);
    // No iOS o Intercom usa o token APNs, que pode existir sem o do FCM.
    unawaited(IntercomService.enviarTokenPush(tokenFcm: token));
  }

  /// Token do FCM esperando o APNs no iOS; falha vai ao Sentry (sem o token).
  static Future<String?> _tokenDoAparelho() {
    final messaging = FirebaseMessaging.instance;
    return obterTokenFcm(
      fcm: messaging.getToken,
      apns: defaultTargetPlatform == TargetPlatform.iOS
          ? messaging.getAPNSToken
          : null,
      avisar: _avisarFalhaDoRegistro,
    );
  }

  static bool _falhaAvisada = false;

  /// Uma vez por abertura: sem token o push do aparelho não chega.
  static void _avisarFalhaDoRegistro(String motivo) {
    if (kDebugMode) debugPrint('[FCM] registro falhou: $motivo');
    if (_falhaAvisada) return;
    _falhaAvisada = true;
    unawaited(
      Sentry.captureMessage(
        'Push sem token no aparelho: $motivo',
        level: SentryLevel.warning,
      ),
    );
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
      // Toque na resposta do suporte: abre a conversa no Intercom.
      if (await IntercomService.ehPushDoIntercom(data)) {
        await IntercomService.openMessenger();
        return;
      }
      if (data['type'] == 'plan_sync') {
        await _dispatchPlanSync(data);
      }
      // "Nova versão do Focux": confere a versão agora e oferece atualizar.
      if (data['type'] == 'versao') {
        AtualizacaoScope.verificarAgora();
        return;
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

  /// Registra o aparelho agora (botão de teste). Nulo quando deu certo;
  /// senão o motivo, com a etapa em que o início parou.
  static Future<String?> registrarAgora(ApiClient apiClient) async {
    try {
      if (await SecureStorage.getToken() == null) return 'sem sessão';
      final motivos = <String>[];
      final messaging = FirebaseMessaging.instance;
      final token = await obterTokenFcm(
        fcm: messaging.getToken,
        apns:
            defaultTargetPlatform == TargetPlatform.iOS
                ? messaging.getAPNSToken
                : null,
        avisar: motivos.add,
        tentativas: 5,
        limite: const Duration(seconds: 10),
      );
      if (token == null) {
        final motivo =
            '${motivos.isEmpty ? 'sem token' : motivos.first} (início: $_etapa)';
        unawaited(
          Sentry.captureMessage(
            'Push sem token no teste: $motivo',
            level: SentryLevel.warning,
          ),
        );
        return motivo;
      }
      await apiClient.dio.post('/api/fcm/token', data: {'token': token});
      _etapa = 'registrado';
      return null;
    } catch (e) {
      return 'registro: ${motivoDoErro(e)} (início: $_etapa)';
    }
  }

  /// Após login — boot pode ter rodado `init` sem JWT.
  static Future<void> registrarSeAutenticado(ApiClient apiClient) async {
    try {
      final jwtToken = await SecureStorage.getToken();
      if (jwtToken == null) return;
      final token = await _tokenDoAparelho();
      if (token == null) return;
      await _registrarToken(token, apiClient);
    } catch (e) {
      if (kDebugMode) debugPrint('[Focux] FCM post-login register error: $e');
    }
  }

  static Future<void>? _permissionInFlight;

  /// Aparelho recusou notificações: o sino continua, o push não chega.
  static Future<bool> permissaoNegada() async {
    if (kIsWeb) return false;
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.denied;
    } catch (_) {
      return false;
    }
  }

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
        // iOS: botão "Ajustes de notificação do Focux" nos Ajustes do sistema,
        // que abre Perfil > Notificações (AppDelegate).
        providesAppNotificationSettings: true,
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
