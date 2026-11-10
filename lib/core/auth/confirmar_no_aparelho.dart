import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Pede Face ID, digital ou o código do aparelho antes de uma ação sensível.
abstract class ConfirmarNoAparelho {
  /// `true` quando confirmou ou quando o aparelho não tem trava nenhuma
  /// (nesse caso a folha de confirmação do app é a única barreira).
  Future<bool> confirmar(String motivo);
}

class ConfirmarNoAparelhoLocalAuth implements ConfirmarNoAparelho {
  ConfirmarNoAparelhoLocalAuth([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> confirmar(String motivo) async {
    if (kIsWeb) return true;
    try {
      if (!await _auth.isDeviceSupported()) return true;
      return await _auth.authenticate(
        localizedReason: motivo,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}

final confirmarNoAparelhoProvider = Provider<ConfirmarNoAparelho>(
  (ref) => ConfirmarNoAparelhoLocalAuth(),
);
