import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client_connection_pool.dart';
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
      ),
    );

    TlsCertificatePinning.apply(_dio);
    configureHttpConnectionPool(_dio);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (_shouldUseIdempotency(options) &&
              !_hasHeader(options.headers, 'Idempotency-Key')) {
            options.headers['Idempotency-Key'] = _newIdempotencyKey();
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          final method = response.requestOptions.method.toUpperCase();
          if (method == 'GET' && response.statusCode == 200) {
            final path = response.requestOptions.path;
            if (_shouldCachePath(path)) {
              LocalCache.put(
                LocalCache.keyFor(response.requestOptions),
                response.data,
                ttl: _cacheTtlForPath(path),
              );
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
              await OfflineSyncService.enqueueRequest(e.requestOptions);
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
                final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
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
                _isRefreshing = false;
                return handler.resolve(retryResp);
              }
            } catch (refreshErr) {
              debugPrint('[ApiClient] Refresh failed: $refreshErr');
            }
            _isRefreshing = false;
          }

          if (!_isRefreshing &&
              _shouldInvalidateSession(e) &&
              e.requestOptions.extra['fxNoInvalidate'] != true) {
            await SessionInvalidator.invalidate(
              reason:
                  'API ${e.response?.statusCode} em ${e.requestOptions.path}',
            );
          }

          // ── Error Reporter ──────────────────────────────────────
          if (e.requestOptions.path != '/api/suporte/analisar-erro' &&
              !_isAuthPath(e.requestOptions.path)) {
            try {
              final token = await SecureStorage.getToken();
              final role = await SecureStorage.getRole();
              if (token != null && role == 'PERSONAL') {
                final reporterDio = Dio(BaseOptions(baseUrl: _baseUrl));
                reporterDio.options.headers['Authorization'] = 'Bearer $token';
                await reporterDio.post(
                  '/api/suporte/analisar-erro',
                  data: {
                    'erro':
                        e.message ?? e.error?.toString() ?? 'Erro desconhecido',
                    'stacktrace':
                        'Path: ${e.requestOptions.path}\nMethod: ${e.requestOptions.method}\nStatus: ${e.response?.statusCode}\nResponse: ${e.response?.data}',
                  },
                );
              }
            } catch (_) {
              // Error reporter is best-effort telemetry — silent fail is correct.
            }
          }
          handler.next(e);
        },
      ),
    );

    // Tenta sincronizar a fila quando a api client for instanciada
    Future.microtask(() => OfflineSyncService.syncPendingRequests(_dio));
  }

  Dio get dio => _dio;

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
    if (_isAuthPath(options.path)) return false;
    if (options.path == '/api/suporte/analisar-erro') return false;

    final method = options.method.toUpperCase();
    return method == 'POST' || method == 'PUT' || method == 'DELETE';
  }

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

  /// Lista de prefixos de rota cuja resposta GET deve ser cacheada
  /// localmente para uso offline. Mantemos o conjunto pequeno e
  /// dirigido aos fluxos críticos do dia-a-dia (Hoje, Alunos, Treinos).
  static bool _shouldCachePath(String path) {
    const cacheable = [
      '/api/personal/perfil',
      '/api/planos/me',
      '/api/planos/vitrine',
      '/api/alunos',
      '/api/treinos',
      '/api/dashboard',
      '/api/hoje',
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

  static Duration? _cacheTtlForPath(String path) {
    if (path.startsWith('/api/planos/vitrine')) {
      return PlanoCachePolicy.vitrineMaxAge;
    }
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
      return status == 408 || status == 429 || status >= 500;
    }
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.unknown;
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
}
