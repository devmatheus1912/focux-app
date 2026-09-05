import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Credencial Apple pronta para `POST /api/auth/apple`.
class AppleSignInCredential {
  const AppleSignInCredential({
    required this.identityToken,
    this.fullName,
    this.email,
  });

  final String identityToken;
  final String? fullName;
  final String? email;
}

/// Encapsula [SignInWithApple] com erros recuperáveis.
class AppleSignInService {
  const AppleSignInService();

  /// iOS/macOS nativo. Android exige Services ID — fora do escopo deste ship.
  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  /// Dispara o fluxo. Cancelamento do usuário → null.
  Future<AppleSignInCredential?> signIn() async {
    if (!isSupportedPlatform) {
      throw PlatformException(
        code: 'apple_sign_in_unsupported',
        message: 'Sign in with Apple não está disponível nesta plataforma.',
      );
    }

    final available = await SignInWithApple.isAvailable();
    if (!available) {
      throw PlatformException(
        code: 'apple_sign_in_unavailable',
        message: 'Sign in with Apple não está disponível neste aparelho.',
      );
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // identityToken já vem como String JWT (não bytes).
      final identityToken = credential.identityToken?.trim();
      if (identityToken == null || identityToken.isEmpty) {
        throw PlatformException(
          code: 'apple_sign_in_no_token',
          message: 'Apple não retornou identityToken.',
        );
      }

      final given = credential.givenName?.trim();
      final family = credential.familyName?.trim();
      final parts = <String>[
        if (given != null && given.isNotEmpty) given,
        if (family != null && family.isNotEmpty) family,
      ];
      final fullName = parts.isEmpty ? null : parts.join(' ');
      final email = credential.email?.trim();

      return AppleSignInCredential(
        identityToken: identityToken,
        fullName: fullName,
        email: (email == null || email.isEmpty) ? null : email,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      throw PlatformException(
        code: 'apple_sign_in_${error.code.name}',
        message: error.message,
      );
    } on PlatformException {
      rethrow;
    } catch (error, stack) {
      Error.throwWithStackTrace(
        PlatformException(
          code: 'apple_sign_in',
          message: error.toString(),
          details: error.runtimeType.toString(),
        ),
        stack,
      );
    }
  }
}
