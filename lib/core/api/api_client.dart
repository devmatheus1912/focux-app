import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';
import 'offline_sync_service.dart';
import 'dart:io';

class ApiClient {
  static const _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://focux-backend.onrender.com',
  );

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
}
