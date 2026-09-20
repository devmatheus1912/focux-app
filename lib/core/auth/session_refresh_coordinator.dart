import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/tls_certificate_pinning.dart';
import '../config/env.dart';
import '../storage/secure_storage.dart';
import 'jwt_access_exp.dart';
import 'session_invalidator.dart';

/// Resultado de um refresh (ou skip) de access token.
enum SessionRefreshOutcome {
  /// Access ainda válido; nada feito.
  fresh,

  /// Novos tokens gravados.
  refreshed,

  /// Rede / 429 / timeout — **não** derruba sessão.
  failedRetryable,

  /// Refresh rejeitado (401/403) ou sem refresh token — sessão invalidada.
  failedFatal,
}

/// Single-flight: N×401 esperam o mesmo refresh; resume/online reusam a mesma trilha.
abstract final class SessionRefreshCoordinator {
  SessionRefreshCoordinator._();

  static Completer<SessionRefreshOutcome>? _flight;
  static final Random _jitter = Random();

  /// Testes / resume: destrava Completer órfão sem invalidar.
  static void resetStuckLock() {
    final flight = _flight;
    if (flight == null || flight.isCompleted) {
      _flight = null;
      return;
    }
    flight.complete(SessionRefreshOutcome.failedRetryable);
    _flight = null;
  }

  @visibleForTesting
  static void resetForTest() {
    _flight = null;
  }

  /// Garante access fresco. [force] ignora `exp` (path 401).
  static Future<SessionRefreshOutcome> ensureFreshAccess({
    bool force = false,
    Duration skew = const Duration(minutes: 5),
  }) {
    final existing = _flight;
    if (existing != null) return existing.future;
    return _run(force: force, skew: skew);
  }

  static Future<SessionRefreshOutcome> _run({
    required bool force,
    required Duration skew,
  }) async {
    final access = await SecureStorage.getToken();
    if (access == null || access.isEmpty) {
      return SessionRefreshOutcome.failedFatal;
    }
    if (!force && !JwtAccessExp.isExpiringSoon(access, skew: skew)) {
      return SessionRefreshOutcome.fresh;
    }

    final refresh = await SecureStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      await SessionInvalidator.invalidate(reason: 'refresh token ausente');
      return SessionRefreshOutcome.failedFatal;
    }

    final completer = Completer<SessionRefreshOutcome>();
    _flight = completer;
    try {
      final outcome = await _performRefresh(refresh);
      if (!completer.isCompleted) completer.complete(outcome);
      return outcome;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SessionRefresh] unexpected: $e');
      }
      const outcome = SessionRefreshOutcome.failedRetryable;
      if (!completer.isCompleted) completer.complete(outcome);
      return outcome;
    } finally {
      if (identical(_flight, completer)) _flight = null;
    }
  }

  static Future<SessionRefreshOutcome> _performRefresh(
    String refreshToken,
  ) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 12),
        headers: const {'Content-Type': 'application/json'},
        persistentConnection: false,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    TlsCertificatePinning.apply(dio);

    try {
      var resp = await dio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      // Uma retentativa com jitter em 429 — sem invalidar sessão.
      if (resp.statusCode == 429) {
        await Future<void>.delayed(
          Duration(milliseconds: 350 + _jitter.nextInt(700)),
        );
        resp = await dio.post<Map<String, dynamic>>(
          '/api/auth/refresh',
          data: {'refreshToken': refreshToken},
        );
        if (resp.statusCode == 429) {
          return SessionRefreshOutcome.failedRetryable;
        }
      }

      final status = resp.statusCode ?? 0;
      if (status == 401 || status == 403) {
        await SessionInvalidator.invalidate(
          reason: 'refresh HTTP $status',
        );
        return SessionRefreshOutcome.failedFatal;
      }
      if (status < 200 || status >= 300) {
        return SessionRefreshOutcome.failedRetryable;
      }

      final body = resp.data;
      final newToken = body?['token'] as String?;
      if (newToken == null || newToken.isEmpty) {
        return SessionRefreshOutcome.failedRetryable;
      }
      await SecureStorage.saveToken(newToken);
      final newRefresh = body?['refreshToken'] as String?;
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await SecureStorage.saveRefreshToken(newRefresh);
      }
      return SessionRefreshOutcome.refreshed;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        await SessionInvalidator.invalidate(
          reason: 'refresh Dio $status',
        );
        return SessionRefreshOutcome.failedFatal;
      }
      // Rede / timeout / 5xx — sessão continua.
      if (kDebugMode) {
        debugPrint(
          '[SessionRefresh] retryable type=${e.type.name} status=$status',
        );
      }
      return SessionRefreshOutcome.failedRetryable;
    } on TimeoutException {
      return SessionRefreshOutcome.failedRetryable;
    }
  }

  /// true se o caller deve retentar a request original com o Bearer atual.
  static bool shouldRetryRequest(SessionRefreshOutcome outcome) {
    return outcome == SessionRefreshOutcome.refreshed ||
        outcome == SessionRefreshOutcome.fresh;
  }
}
