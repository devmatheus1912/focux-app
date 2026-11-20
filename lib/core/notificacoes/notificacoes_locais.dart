import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:url_launcher/url_launcher.dart';

import '../router/app_router.dart';
import 'tipos_de_notificacao.dart';

/// Notificações do próprio aparelho (SPEC-notificacoes, 20/11): canais do
/// Android por tipo (o push do servidor usa o mesmo `channel_id`), aviso do
/// fim do descanso e o toque que abre a rota certa.
abstract final class NotificacoesLocais {
  static final plugin = FlutterLocalNotificationsPlugin();
  static bool _iniciado = false;

  /// iOS: "Ajustes de notificação do Focux" nos Ajustes do sistema
  /// (AppDelegate → `abrirAjustesDoApp`).
  static const _canalNativo = MethodChannel('focux/notificacoes');

  static Future<void> init() async {
    if (_iniciado || kIsWeb) return;
    _iniciado = true;
    try {
      tzdata.initializeTimeZones();
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // A permissão é pedida pelo push (FcmService), depois do login.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestSoundPermission: false,
            requestBadgePermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) => abrirRota(r.payload),
      );
      await criarCanais();
      final abertura = await plugin.getNotificationAppLaunchDetails();
      if (abertura?.didNotificationLaunchApp ?? false) {
        abrirRota(abertura?.notificationResponse?.payload);
      }
      _canalNativo.setMethodCallHandler((call) async {
        if (call.method == 'abrirAjustesDoApp') abrirRota(rotaDosAjustes);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[Notificacoes] init: $e');
    }
  }

  static const rotaDosAjustes = '/perfil/notificacoes';

  /// Um canal por tipo, com o nome da tela Perfil > Notificações.
  static Future<void> criarCanais() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final android =
        plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (android == null) return;
    for (final canal in canaisAndroid) {
      await android.createNotificationChannel(canal);
    }
  }

  /// Canais desligados no sistema (Android), para a tela mostrar "desligado".
  static Future<Set<String>> canaisDesligados() async {
    if (kIsWeb || !Platform.isAndroid) return const {};
    try {
      final android =
          plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      final canais = await android?.getNotificationChannels() ?? const [];
      return {
        for (final c in canais)
          if (c.importance == Importance.none) c.id,
      };
    } catch (_) {
      return const {};
    }
  }

  /// Toque numa notificação local: só rota interna.
  static void abrirRota(String? rota) {
    if (rota == null || !rota.startsWith('/')) return;
    // Já na tela (voltou do bloqueio para a execução): não empilha outra.
    if (jaEstaEm(rota, atual: _rotaAtual())) return;
    try {
      AppRouter.router.push(rota);
    } catch (_) {
      // Router ainda subindo (abertura a frio): tenta no próximo frame.
      scheduleMicrotask(() {
        try {
          AppRouter.router.push(rota);
        } catch (_) {}
      });
    }
  }
}

/// Mesma tela, ignorando a query (o aviso do descanso volta para a execução).
bool jaEstaEm(String rota, {required String? atual}) =>
    atual != null && Uri.parse(rota).path == Uri.parse(atual).path;

String? _rotaAtual() {
  try {
    return AppRouter.router.routerDelegate.currentConfiguration.uri.toString();
  } catch (_) {
    return null;
  }
}

/// Notificações negadas: Android 13+ pede de novo; iOS abre os Ajustes do app.
Future<void> abrirAjustesDeNotificacao() async {
  if (kIsWeb) return;
  try {
    if (Platform.isAndroid) {
      await NotificacoesLocais.plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return;
    }
    await launchUrl(Uri.parse('app-settings:'));
  } catch (_) {}
}
