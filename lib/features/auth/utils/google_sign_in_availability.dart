import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../../../core/config/env.dart';

/// Google no app: Web client pro backend; iOS exige client OAuth nativo separado.
bool googleSignInConfiguredInApp() {
  if (Env.googleWebClientId.trim().isEmpty) return false;
  if (!kIsWeb && Platform.isIOS) {
    return Env.googleIosNativeClientId != null;
  }
  return true;
}
