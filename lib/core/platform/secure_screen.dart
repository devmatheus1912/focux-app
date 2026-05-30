import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Anti-screenshot na tela de revisão de assinatura (FLAG_SECURE no Android).
class SecureScreen {
  SecureScreen._();

  static const _channel = MethodChannel('com.focux.focux_app/secure_screen');

  static Future<void> enable() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('enable');
    } catch (_) {}
  }

  static Future<void> disable() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('disable');
    } catch (_) {}
  }
}
