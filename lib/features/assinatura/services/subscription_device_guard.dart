import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class SubscriptionDeviceGuard {
  SubscriptionDeviceGuard._();

  /// Dispositivo com jailbreak/root — bloqueia checkout.
  static Future<bool> isJailbroken() async {
    if (kIsWeb) return false;
    try {
      return await FlutterJailbreakDetection.jailbroken;
    } catch (_) {
      return false;
    }
  }

  /// Modo desenvolvedor (USB debugging) — não equivale a jailbreak.
  /// Bloqueia só a compra, não a navegação em Planos.
  static Future<bool> isDeveloperMode() async {
    if (kIsWeb) return false;
    try {
      return await FlutterJailbreakDetection.developerMode;
    } catch (_) {
      return false;
    }
  }

  /// Comprometido para pagamento = jailbreak OU developer mode.
  static Future<bool> isCompromised() async {
    if (kIsWeb) return false;
    try {
      final jailbroken = await isJailbroken();
      final devMode = await isDeveloperMode();
      return jailbroken || devMode;
    } catch (_) {
      return false;
    }
  }
}
