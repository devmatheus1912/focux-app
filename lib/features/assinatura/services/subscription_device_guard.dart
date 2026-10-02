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

  /// Só jailbreak/root bloqueia a compra. Modo desenvolvedor é comum em
  /// aparelho normal (e nos de revisão da loja); o recibo é validado no backend.
  static Future<bool> isCompromised() => isJailbroken();
}
