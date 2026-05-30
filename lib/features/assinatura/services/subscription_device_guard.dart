import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class SubscriptionDeviceGuard {
  SubscriptionDeviceGuard._();

  static Future<bool> isCompromised() async {
    if (kIsWeb) return false;
    try {
      final jailbroken = await FlutterJailbreakDetection.jailbroken;
      final devMode = await FlutterJailbreakDetection.developerMode;
      return jailbroken || devMode;
    } catch (_) {
      return false;
    }
  }
}
