import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Credencial Apple pronta para `POST /api/auth/apple`.
class AppleSignInCredential {
  const AppleSignInCredential({
    required this.identityToken,
    this.authorizationCode,
    this.rawNonce,
    this.fullName,
    this.email,
  });

  final String identityToken;

  /// Troca no backend por refresh token (revogação na exclusão de conta).
  final String? authorizationCode;

  /// O token carrega o SHA-256 deste valor; o backend confere.
  final String? rawNonce;
  final String? fullName;
  final String? email;
}

/// Nonce aleatório (charset do exemplo da Apple, sem caracteres ambíguos).
String appleRawNonce([int length = 32, Random? random]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final rng = random ?? Random.secure();
  return List.generate(
    length,
    (_) => charset[rng.nextInt(charset.length)],
  ).join();
}

String appleNonceHash(String rawNonce) =>
    sha256.convert(utf8.encode(rawNonce)).toString();

/// Encapsula [SignInWithApple] com erros recuperáveis.
class AppleSignInService {
  const AppleSignInService();

  /// iOS/macOS nativo. Android exige Services ID — fora do escopo deste ship.
  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  /// Botão Apple no iOS não depende do backend (guideline 4.8).
  static Future<bool> isAvailableOnDevice() async {
    if (!isSupportedPlatform) return false;
    try {
      return await SignInWithApple.isAvailable();
    } catch (_) {
      return false;
    }
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

    final rawNonce = appleRawNonce();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: appleNonceHash(rawNonce),
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
      final code = credential.authorizationCode.trim();

      return AppleSignInCredential(
        identityToken: identityToken,
        authorizationCode: code.isEmpty ? null : code,
        rawNonce: rawNonce,
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
