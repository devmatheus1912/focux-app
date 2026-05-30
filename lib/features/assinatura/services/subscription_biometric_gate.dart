import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Confirma identidade antes de iniciar checkout na loja (Face ID / Touch ID / PIN).
class SubscriptionBiometricGate {
  SubscriptionBiometricGate._();

  static final _auth = LocalAuthentication();

  static Future<bool> confirmSubscription({
    required String planName,
  }) async {
    if (kIsWeb) return true;

    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck && !isSupported) return true;

      return _auth.authenticate(
        localizedReason: 'Confirme para assinar o plano $planName',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
