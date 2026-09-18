import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client_connection_pool.dart';
import 'api_etag_store.dart';
import '../auth/session_invalidator.dart';
import '../config/env.dart';
import '../planos/plano_cache_policy.dart';
import '../storage/secure_storage.dart';
import 'offline_sync_service.dart';
import 'tls_certificate_pinning.dart';

class ApiClient {
  static String get _baseUrl => Env.apiUrl;
  static final Random _idempotencyRandom = Random.secure();

  late final Dio _dio;
  bool _isRefreshing = false;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        // 304 Not Modified = sucesso (ETag / If-None-Match).
        validateStatus: (status) => status != null && status >= 200 && status < 400,
      ),
    );

    TlsCertificatePinning.apply(_dio);
    configureHttpConnectionPool(_dio);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Auth mutações usam [newDetachedAuthDio] — não reciclar o pool
          // compartilhado aqui (close → Client is closed no Apple).
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (options.method.toUpperCase() == 'GET' &&
              options.extra['fxSkipEtag'] != true) {
            final key = ApiEtagStore.keyFor(
              method: options.method,
              path: options.path,
            );
            final etag = ApiEtagStore.get(key);
            if (etag != null && etag.isNotEmpty) {
              // Home BFF: só If-None-Match se houver body no ClientCache.
              if (ApiEtagStore.requiresLocalBody(options.path) &&
                  !ApiEtagStore.hasLocalBodyFor(options.path)) {
                ApiEtagStore.remove(key);
              } else {
                options.headers['If-None-Match'] = etag;
              }
            }
          }
          if (_shouldUseIdempotency(options) &&
              !_hasHeader(options.headers, 'Idempotency-Key')) {
            final scope = options.extra[_idempotencyScopeKey];
            options.headers['Idempotency-Key'] =
                scope is String && scope.isNotEmpty
                    ? _idempotencyKeyForScope(scope)
                    : _newIdempotencyKey();
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          final method = response.requestOptions.method.toUpperCase();
          if (method == 'GET') {
            final etag = response.headers.value('etag');
            if (etag != null && etag.isNotEmpty) {
              ApiEtagStore.put(
                ApiEtagStore.keyFor(
                  method: method,
                  path: response.requestOptions.path,
                ),
                etag,
              );
            }
            if (response.statusCode == 200) {
              final path = response.requestOptions.path;
              if (_shouldCachePath(path)) {
                LocalCache.put(
                  LocalCache.keyFor(response.requestOptions),
                  response.data,
                  ttl: _cacheTtlForPath(path),
                );
              }
            }
          }
          handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (_shouldRetry(e)) {
            final attempt =
                (e.requestOptions.extra['fxRetryAttempt'] as int?) ?? 0;
            if (attempt < 2) {
              e.requestOptions.extra['fxRetryAttempt'] = attempt + 1;
              await Future.delayed(Duration(milliseconds: 700 * (attempt + 1)));
              try {
                final retryResp = await _dio.fetch(e.requestOptions);
                return handler.resolve(retryResp);
              } catch (_) {
                // Keep the original error path so cache/offline/refresh logic still applies.
              }
            }
          }

          // ── Offline Queue ───────────────────────────────────────
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout) {
            final method = e.requestOptions.method.toUpperCase();
            if (_canQueueOfflineMutation(e.requestOptions)) {
              final queued = await OfflineSyncService.enqueueRequest(
                e.requestOptions,
              );
              if (queued) {
                return handler.resolve(
                  Response(
                    requestOptions: e.requestOptions,
                    statusCode: 202,
                    data: {
                      'status': 'queued',
                      'message': 'Offline. Sincronizará quando houver rede.',
                    },
                  ),
                );
              }
            }

            if (method == 'GET' && _shouldCachePath(e.requestOptions.path)) {
              final cached = await LocalCache.get(
                LocalCache.keyFor(e.requestOptions),
              );
              if (cached != null) {
                return handler.resolve(
                  Response(
                    requestOptions: e.requestOptions,
                    statusCode: 200,
                    data: cached,
                    headers: Headers.fromMap({
                      'x-fx-from-cache': ['true'],
                    }),
                  ),
                );
              }
            }
          }

          // ── Auto Refresh Token on 401 ─────────────────────────
          if (e.response?.statusCode == 401 &&
              !_isAuthPath(e.requestOptions.path) &&
              !_isRefreshing) {
            _isRefreshing = true;
            try {
              final refreshToken = await SecureStorage.getRefreshToken();
              if (refreshToken != null) {
                final refreshDio = Dio(
                  BaseOptions(
                    baseUrl: _baseUrl,
                    connectTimeout: const Duration(seconds: 10),
                    receiveTimeout: const Duration(seconds: 10),
                    sendTimeout: const Duration(seconds: 10),
                  ),
                );
                TlsCertificatePinning.apply(refreshDio);
                final resp = await refreshDio.post(
                  '/api/auth/refresh',
                  data: {'refreshToken': refreshToken},
                );
                final newToken = resp.data['token'] as String;
                final newRefreshToken = resp.data['refreshToken'] as String?;
                await SecureStorage.saveToken(newToken);
                if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
                  await SecureStorage.saveRefreshToken(newRefreshToken);
                }

                // Retry original request with new token
                e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                final retryResp = await _dio.fetch(e.requestOptions);
                return handler.resolve(retryResp);
              }
            } catch (refreshErr) {
              if (kDebugMode) {
                final status = refreshErr is DioException
                    ? refreshErr.response?.statusCode
                    : null;
                debugPrint(
                  '[ApiClient] Refresh failed${status != null ? ' status=$status' : ''}',
                );
              }
            } finally {
              _isRefreshing = false;
            }
          }

          if (!_isRefreshing &&
              _shouldInvalidateSession(e) &&
              e.requestOptions.extra['fxNoInvalidate'] != true) {
            resetIdempotencyScopes();
            await SessionInvalidator.invalidate(
              reason:
                  'API ${e.response?.statusCode} em ${e.requestOptions.path}',
            );
          }

          // ── Error Reporter (best-effort, gated) ────────────────
          // Never await: concurrent failures would stampede the BE.
          // Gate is sync so 500 parallel onError calls can't all pass.
          if (_tryReserveErrorReportSlot(e)) {
            // ignore: unawaited_futures
            _sendErrorReport(e);
          }
          handler.next(e);
        },
      ),
    );

    // Tenta sincronizar a fila quando a api client for instanciada
    Future.microtask(() => OfflineSyncService.syncPendingRequests(_dio));
  }

  Dio get dio => _dio;

  /// Dio isolado do pool principal (pin connect-time, sem recycle compartilhado).
  ///
  /// Login Apple/Google: o sheet nativo dispara `resumed` enquanto o POST roda;
  /// reciclar/fechar o HttpClient do [_dio] gerava
  /// `StateError: Bad state: Client is closed`.
  Dio newDetachedAuthDio() {
    final d = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: const {'Content-Type': 'application/json'},
        persistentConnection: false,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 400,
      ),
    );
    TlsCertificatePinning.apply(d);
    return d;
  }

  /// Após background longo: destrava refresh. Recicla só se [away] ≥ 30s
  /// (sheet Apple costuma passar de 5s — não mexer no pool no dismiss).
  void resetAfterAppResume([Duration away = Duration.zero]) {
    _isRefreshing = false;
    if (away < kHttpPoolResumeRecycleMinAway) return;
    recycleHttpConnectionPool(_dio);
  }

  static bool _shouldUseIdempotency(RequestOptions options) {
    if (_isAuthPath(options.path)) return false;
    if (options.path == '/api/suporte/analisar-erro') return false;
    if (options.path == '/api/uploads') return false;
    if (options.data is FormData) return false;

    final normalized = options.method.toUpperCase();
    return normalized == 'POST' ||
        normalized == 'PUT' ||
        normalized == 'PATCH' ||
        normalized == 'DELETE';
  }

  static bool _canQueueOfflineMutation(RequestOptions options) {
    if (options.extra['fxNoOfflineQueue'] == true) return false;
    if (_isAuthPath(options.path)) return false;
    if (options.path == '/api/suporte/analisar-erro') return false;
    if (OfflineSyncService.isSensitivePath(options.path)) return false;

    final method = options.method.toUpperCase();
    return method == 'POST' || method == 'PUT' || method == 'DELETE';
  }

  @visibleForTesting
  static bool canQueueOfflineMutationForTest(RequestOptions options) =>
      _canQueueOfflineMutation(options);

  static bool _hasHeader(Map<String, dynamic> headers, String name) {
    final target = name.toLowerCase();
    return headers.keys.any((key) => key.toLowerCase() == target);
  }

  static String _newIdempotencyKey() {
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final randA = _idempotencyRandom.nextInt(1 << 31).toRadixString(36);
    final randB = _idempotencyRandom.nextInt(1 << 31).toRadixString(36);
    return 'fx-$time-$randA$randB';
  }

  /// Declara que a requisição representa uma operação identificável, para que
  /// duas submissões dela compartilhem a mesma `Idempotency-Key`.
  ///
  /// Sem isso a chave é nova a cada tentativa, e aí a idempotência do servidor
  /// só protege reenvio de transporte — dois toques no mesmo botão chegam como
  /// duas mutações legítimas e distintas. O [scope] deve identificar a
  /// operação e o alvo, não o instante: `'mensalidade-pagar-42'`, não
  /// `'pagar-$now'`.
  static Options idempotent(String scope, {Map<String, dynamic>? extra}) {
    return Options(extra: {...?extra, _idempotencyScopeKey: scope});
  }

  static const _idempotencyScopeKey = 'fxIdempotencyScope';

  /// Janela em que o mesmo escopo reaproveita a chave já emitida. Cobre toque
  /// duplo e "tentar de novo" impaciente, e ainda deixa a mesma operação ser
  /// repetida de propósito depois.
  ///
  /// É reaproveitamento por escopo em memória, não bucket de tempo, de
  /// propósito: bucket tem borda, e duas submissões em lados opostos dela
  /// receberiam chaves diferentes justamente no caso que precisa colapsar.
  static const _idempotencyScopeTtl = Duration(minutes: 10);
  static final Map<String, _ScopedIdempotencyKey> _scopedKeys = {};

  static String _idempotencyKeyForScope(String scope) {
    final now = DateTime.now();
    _scopedKeys.removeWhere(
      (_, issued) => now.difference(issued.issuedAt) > _idempotencyScopeTtl,
    );
    final existing = _scopedKeys[scope];
    if (existing != null) return existing.key;
    final key = _newIdempotencyKey();
    _scopedKeys[scope] = _ScopedIdempotencyKey(key, now);
    return key;
  }

  /// Limpa chaves em memória no logout / invalidate de sessão.
  static void resetIdempotencyScopes() => _scopedKeys.clear();

  /// Catálogo não-PII apenas (planos). Dashboard/hoje/treinos ficam fora do disco.
  static bool _shouldCachePath(String path) {
    if (_isSensitiveDiskCachePath(path)) return false;
    const cacheable = [
      '/api/planos/me',
    ];
    for (final prefix in cacheable) {
      if (path == prefix ||
          path.startsWith('$prefix?') ||
          path.startsWith('$prefix/')) {
        return true;
      }
    }
    return false;
  }

  /// Nunca gravar em SharedPreferences (PII / saúde / operação).
  static bool _isSensitiveDiskCachePath(String path) {
    const blocked = [
      '/api/alunos',
      '/api/personal/perfil',
      '/api/lgpd',
      '/api/comunidade',
      '/api/health',
      '/api/webhooks',
      '/api/dashboard',
      '/api/hoje',
      '/api/treinos',
      '/api/ia',
      '/api/leads',
    ];
    for (final prefix in blocked) {
      if (path == prefix ||
          path.startsWith('$prefix?') ||
          path.startsWith('$prefix/')) {
        return true;
      }
    }
    return false;
  }

  static Duration? _cacheTtlForPath(String path) {
    if (path.startsWith('/api/planos/me')) {
      return PlanoCachePolicy.planosMeHttpCacheTtl;
    }
    return null;
  }

  static bool _shouldRetry(DioException e) {
    if (e.requestOptions.extra['fxNoRetry'] == true) return false;
    if (_isAuthPath(e.requestOptions.path)) return false;
    if (e.requestOptions.path == '/api/suporte/analisar-erro') return false;
    if (e.response != null) {
      final status = e.response?.statusCode ?? 0;
      // Never auto-retry 429 — amplifies rate-limit storms on the BE.
      return status == 408 || status >= 500;
    }
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.unknown;
  }

  /// Cap client→`/api/suporte/analisar-erro` so a failing screen can't DDoS
  /// the tenant rate-limit bucket (BE allows 10/min; we stay well under).
  static const int _errorReportMaxPerWindow = 5;
  static const Duration _errorReportWindow = Duration(seconds: 60);
  static final List<DateTime> _errorReportAt = <DateTime>[];
  static final Set<String> _errorReportFingerprints = <String>{};
  static DateTime? _errorReportFingerprintWindowStart;
  static Dio? _errorReporterDio;

  /// Sync reservation: returns false if this error must not hit the BE.
  @visibleForTesting
  static bool tryReserveErrorReportSlotForTest(DioException e) =>
      _tryReserveErrorReportSlot(e);

  @visibleForTesting
  static void resetErrorReportGateForTest() {
    _errorReportAt.clear();
    _errorReportFingerprints.clear();
    _errorReportFingerprintWindowStart = null;
  }

  static bool _tryReserveErrorReportSlot(DioException e) {
    if (!_shouldReportApiError(e)) return false;

    final now = DateTime.now();
    _errorReportAt.removeWhere(
      (t) => now.difference(t) > _errorReportWindow,
    );
    if (_errorReportAt.length >= _errorReportMaxPerWindow) return false;

    final windowStart = _errorReportFingerprintWindowStart;
    if (windowStart == null ||
        now.difference(windowStart) > _errorReportWindow) {
      _errorReportFingerprintWindowStart = now;
      _errorReportFingerprints.clear();
    }
    final fingerprint =
        '${e.type.name}|${e.response?.statusCode}|${_normalizePath(e.requestOptions.path)}';
    if (!_errorReportFingerprints.add(fingerprint)) return false;

    _errorReportAt.add(now);
    return true;
  }

  static bool _shouldReportApiError(DioException e) {
    final path = e.requestOptions.path;
    if (path == '/api/suporte/analisar-erro') return false;
    if (_isAuthPath(path)) return false;
    final status = e.response?.statusCode;
    // Auth / rate-limit / client validation are noise for the ticket pipeline.
    if (status == 401 || status == 403 || status == 429) return false;
    if (status != null && status >= 400 && status < 500) return false;
    return true;
  }

  static Future<void> _sendErrorReport(DioException e) async {
    try {
      final token = await SecureStorage.getToken();
      final role = await SecureStorage.getRole();
      if (token == null || role != 'PERSONAL') return;

      final reporter = _errorReporterDio ??= () {
        final d = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
            sendTimeout: const Duration(seconds: 8),
          ),
        );
        TlsCertificatePinning.apply(d);
        return d;
      }();
      reporter.options.headers['Authorization'] = 'Bearer $token';
      await reporter.post(
        '/api/suporte/analisar-erro',
        data: {
          'erro': _safeErrorMessage(e),
          'stacktrace': _safeErrorContext(e),
        },
      );
    } catch (_) {
      // Best-effort telemetry — silent fail is correct.
    }
  }

  static bool _shouldInvalidateSession(DioException e) {
    if (_isAuthPath(e.requestOptions.path)) return false;
    final status = e.response?.statusCode;
    if (status == 401) return true;
    if (status == 403) return _isLikelySessionAuthFailure(e);
    return false;
  }

  static bool _isLikelySessionAuthFailure(DioException e) {
    final data = e.response?.data;
    if (data == null) return true;
    final text = data.toString().toLowerCase();
    if (text.isEmpty) return true;
    return text.contains('full authentication') ||
        text.contains('unauthorized') ||
        text.contains('forbidden') ||
        text.contains('token') ||
        text.contains('jwt') ||
        text.contains('expir') ||
        text.contains('autentic');
  }

  static bool _isAuthPath(String path) {
    return path.contains('/auth/');
  }

  static String _safeErrorMessage(DioException e) {
    final status = e.response?.statusCode;
    final type = e.type.name;
    return 'DioException($type)${status != null ? ' status=$status' : ''}';
  }

  static String _safeErrorContext(DioException e) {
    final path = _normalizePath(e.requestOptions.path);
    return 'Path: $path\nMethod: ${e.requestOptions.method}\nStatus: ${e.response?.statusCode}';
  }

  static String _normalizePath(String path) {
    return path.replaceAll(RegExp(r'/\d+'), '/:id');
  }
}

class _ScopedIdempotencyKey {
  final String key;
  final DateTime issuedAt;

  const _ScopedIdempotencyKey(this.key, this.issuedAt);
}
