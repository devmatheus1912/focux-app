import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/env.dart';
import '../storage/secure_storage.dart';
import 'offline_sync_service.dart';
import 'dart:io';

class ApiClient {
  static String get _baseUrl => Env.apiUrl;

  late final Dio _dio;
  bool _isRefreshing = false;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        final method = response.requestOptions.method.toUpperCase();
        if (method == 'GET' && response.statusCode == 200) {
          final path = response.requestOptions.path;
          if (_shouldCachePath(path)) {
            LocalCache.put(path, response.data);
          }
        }
        handler.next(response);
      },
      onError: (DioException e, handler) async {
        // ── Offline Queue ───────────────────────────────────────
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.error is SocketException) {
          
          final method = e.requestOptions.method.toUpperCase();
          if (method == 'POST' || method == 'PUT' || method == 'DELETE') {
            await OfflineSyncService.enqueueRequest(e.requestOptions);
            return handler.resolve(Response(
              requestOptions: e.requestOptions,
              statusCode: 202,
              data: {'status': 'queued', 'message': 'Offline. Sincronizará quando houver rede.'},
            ));
          }

          if (method == 'GET' && _shouldCachePath(e.requestOptions.path)) {
            final cached = await LocalCache.get(e.requestOptions.path);
            if (cached != null) {
              return handler.resolve(Response(
                requestOptions: e.requestOptions,
                statusCode: 200,
                data: cached,
                headers: Headers.fromMap({'x-fx-from-cache': ['true']}),
              ));
            }
          }
        }

        // ── Auto Refresh Token on 401 ─────────────────────────
        if (e.response?.statusCode == 401 &&
            !e.requestOptions.path.contains('/auth/') &&
            !_isRefreshing) {
          _isRefreshing = true;
          try {
            final refreshToken = await SecureStorage.getRefreshToken();
            if (refreshToken != null) {
              final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
              final resp = await refreshDio.post('/api/auth/refresh', data: {
                'refreshToken': refreshToken,
              });
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
            await SecureStorage.clearAll();
          }
          _isRefreshing = false;
        }

        // ── Error Reporter ──────────────────────────────────────
        if (e.requestOptions.path != '/api/suporte/analisar-erro' &&
            !e.requestOptions.path.contains('/auth/')) {
          try {
            final token = await SecureStorage.getToken();
            final role = await SecureStorage.getRole();
            if (token != null && role == 'PERSONAL') {
              final reporterDio = Dio(BaseOptions(baseUrl: _baseUrl));
              reporterDio.options.headers['Authorization'] = 'Bearer $token';
              await reporterDio.post('/api/suporte/analisar-erro', data: {
                'erro': e.message ?? e.error?.toString() ?? 'Erro desconhecido',
                'stacktrace': 'Path: ${e.requestOptions.path}\nMethod: ${e.requestOptions.method}\nStatus: ${e.response?.statusCode}\nResponse: ${e.response?.data}',
              });
            }
          } catch (reportErr) {
            debugPrint('[ApiClient] Error report failed: $reportErr');
          }
        }
        handler.next(e);
      },
    ));

    // Tenta sincronizar a fila quando a api client for instanciada
    Future.microtask(() => OfflineSyncService.syncPendingRequests(_dio));
  }

  Dio get dio => _dio;

  /// Lista de prefixos de rota cuja resposta GET deve ser cacheada
  /// localmente para uso offline. Mantemos o conjunto pequeno e
  /// dirigido aos fluxos críticos do dia-a-dia (Hoje, Alunos, Treinos).
  static bool _shouldCachePath(String path) {
    const cacheable = [
      '/api/personal/perfil',
      '/api/planos/me',
      '/api/alunos',
      '/api/treinos',
      '/api/dashboard',
      '/api/hoje',
    ];
    for (final prefix in cacheable) {
      if (path == prefix || path.startsWith('$prefix?') || path.startsWith('$prefix/')) {
        return true;
      }
    }
    return false;
  }
}
