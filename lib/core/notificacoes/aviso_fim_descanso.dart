import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notificacoes_locais.dart';
import 'tipos_de_notificacao.dart';

/// Escolhas locais do descanso (Perfil > Notificações). Valem no aparelho:
/// o aviso é agendado aqui, não pelo servidor.
abstract final class PreferenciasDoDescanso {
  static const chaveAviso = 'notif_descanso_ligado';
  static const chaveSom = 'descanso_som_ligado';
  static const chaveDicaPermissao = 'descanso_dica_permissao_vista';

  static Future<bool> avisoLigado() => _ler(chaveAviso);
  static Future<bool> somLigado() => _ler(chaveSom);
  static Future<void> definirAviso(bool v) => _gravar(chaveAviso, v);
  static Future<void> definirSom(bool v) => _gravar(chaveSom, v);

  static Future<bool> _ler(String chave) async {
    try {
      return (await SharedPreferences.getInstance()).getBool(chave) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> _gravar(String chave, bool v) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(chave, v);
    } catch (_) {}
  }
}

/// Fim do descanso com o app em segundo plano ou a tela bloqueada.
abstract interface class AvisoFimDescanso {
  /// Agenda (ou reagenda) o aviso para [fim]. [rota] abre a execução.
  Future<void> agendar({
    required DateTime fim,
    required String corpo,
    required String rota,
  });

  /// Pular, terminar, descartar ou voltar ao app antes do fim.
  Future<void> cancelar();
}

final avisoFimDescansoProvider = Provider<AvisoFimDescanso>(
  (ref) => AvisoFimDescansoLocal(NotificacoesLocais.plugin),
);

/// Título do aviso: o que acabou; o corpo diz a próxima série.
const tituloFimDescanso = 'Descanso acabou';

class AvisoFimDescansoLocal implements AvisoFimDescanso {
  AvisoFimDescansoLocal(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const idAviso = 9001;
  static const idContagem = 9002;

  @override
  Future<void> agendar({
    required DateTime fim,
    required String corpo,
    required String rota,
  }) async {
    if (kIsWeb) return;
    try {
      await cancelar();
      if (!await PreferenciasDoDescanso.avisoLigado()) return;
      final falta = fim.difference(DateTime.now());
      if (falta <= Duration.zero) return;
      await _plugin.zonedSchedule(
        id: idAviso,
        title: tituloFimDescanso,
        body: corpo,
        payload: rota,
        scheduledDate: tz.TZDateTime.now(tz.UTC).add(falta),
        androidScheduleMode: await _modo(),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            canalDescanso,
            'Fim do descanso',
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: true,
            presentBanner: true,
            presentList: true,
            // Fura o Foco com o entitlement Time Sensitive; sem ele, vale "ativo".
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
      );
      if (Platform.isAndroid) await _contagem(fim, falta, corpo, rota);
    } catch (e) {
      if (kDebugMode) debugPrint('[Descanso] agendar: $e');
    }
  }

  /// Alarme exato só onde o sistema já permite (D1 da spec); senão inexato,
  /// com a contagem visível na tela de bloqueio.
  Future<AndroidScheduleMode> _modo() async {
    if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    final exato = await android?.canScheduleExactNotifications() ?? false;
    return exato
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Android: contagem regressiva contínua enquanto dura o descanso.
  Future<void> _contagem(
    DateTime fim,
    Duration falta,
    String corpo,
    String rota,
  ) => _plugin.show(
    id: idContagem,
    title: 'Descansando',
    body: corpo,
    payload: rota,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        canalDescansoContagem,
        'Contagem do descanso',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        onlyAlertOnce: true,
        silent: true,
        showWhen: true,
        when: fim.millisecondsSinceEpoch,
        usesChronometer: true,
        chronometerCountDown: true,
        timeoutAfter: falta.inMilliseconds,
      ),
    ),
  );

  @override
  Future<void> cancelar() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(id: idAviso);
      await _plugin.cancel(id: idContagem);
    } catch (_) {}
  }
}
