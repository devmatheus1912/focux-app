import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/env.dart';

/// Resultado seguro do Google Sign-In (nunca propaga abort nativo como “sucesso”).
class GoogleSignInIdToken {
  const GoogleSignInIdToken({required this.idToken});

  final String idToken;
}

/// Encapsula [GoogleSignIn] com config iOS correta e erros recuperáveis.
///
/// iOS: **não** passa o Web client como `clientId` — isso exigiria URL scheme
/// do reversed Web client e, se ausente, o SDK nativo dá SIGABRT em
/// `GIDSignIn.signInWithOptions`. Usa `GIDClientID` / GoogleService-Info e
/// `serverClientId` = Web client para o backend receber `idToken`.
class GoogleSignInService {
  GoogleSignInService({GoogleSignIn? googleSignIn}) : _injected = googleSignIn;

  final GoogleSignIn? _injected;

  GoogleSignIn _buildClient() {
    if (_injected != null) return _injected;
    final isAndroid = !kIsWeb && Platform.isAndroid;
    return GoogleSignIn(
      // Android: default from google-services.json.
      // iOS: null → Info.plist GIDClientID / GoogleService-Info.plist CLIENT_ID.
      clientId: isAndroid ? null : Env.googleIosClientIdOrNull,
      serverClientId: Env.googleWebClientId,
      scopes: const ['email', 'profile'],
    );
  }

  /// Dispara o fluxo. Cancelamento → null. Falhas → [PlatformException] /
  /// [StateError] (capturáveis no Dart — nunca deixamos config errada
  /// “passar” e estourar no nativo quando dá para detectar antes).
  Future<GoogleSignInIdToken?> signInForIdToken() async {
    _assertServerClientConfigured();
    final google = _buildClient();
    try {
      try {
        await google.signOut();
      } catch (_) {
        // Best-effort: conta residual não deve bloquear novo login.
      }

      final account = await google.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google nao retornou idToken.');
      }
      return GoogleSignInIdToken(idToken: idToken);
    } on PlatformException {
      rethrow;
    } catch (error, stack) {
      // Qualquer erro inesperado vira PlatformException tipada para a UI.
      Error.throwWithStackTrace(
        PlatformException(
          code: 'google_sign_in',
          message: error.toString(),
          details: error.runtimeType.toString(),
        ),
        stack,
      );
    }
  }

  void _assertServerClientConfigured() {
    final web = Env.googleWebClientId.trim();
    if (web.isEmpty || !web.contains('.apps.googleusercontent.com')) {
      throw PlatformException(
        code: 'google_sign_in_config',
        message:
            'GOOGLE_WEB_CLIENT_ID ausente ou inválido neste build. '
            'Regenere o IPA com o dart-define correto.',
      );
    }
  }
}
