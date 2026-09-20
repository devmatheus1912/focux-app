import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_refresh_coordinator.dart';
import '../config/env.dart';
import '../storage/secure_storage.dart';
import 'tls_certificate_pinning.dart';

/// Cliente HTTP dedicado a `/api/iap/*` e `/api/pagamentos/*`.
///
/// Compartilha [SessionRefreshCoordinator] com [ApiClient] — 401 não órfão.
class PaymentApiClient {
  PaymentApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: Env.apiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );
    TlsCertificatePinning.apply(dio);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (_needsIdempotency(options) &&
              !_hasHeader(options.headers, 'Idempotency-Key')) {
            options.headers['Idempotency-Key'] = _newIdempotencyKey();
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401 &&
              e.requestOptions.extra['fxAuthRetried'] != true) {
            final outcome =
                await SessionRefreshCoordinator.ensureFreshAccess(force: true);
            if (SessionRefreshCoordinator.shouldRetryRequest(outcome)) {
              final token = await SecureStorage.getToken();
              if (token != null) {
                e.requestOptions.headers['Authorization'] = 'Bearer $token';
                e.requestOptions.extra['fxAuthRetried'] = true;
                try {
                  final retryResp = await dio.fetch(e.requestOptions);
                  return handler.resolve(retryResp);
                } catch (_) {}
              }
            }
          }
          handler.next(e);
        },
      ),
    );
  }

  late final Dio dio;
  static final Random _idempotencyRandom = Random.secure();

  static bool _needsIdempotency(RequestOptions options) {
    final method = options.method.toUpperCase();
    if (method != 'POST' && method != 'PUT' && method != 'PATCH') {
      return false;
    }
    final path = options.path;
    return path.contains('/api/iap/') || path.contains('/api/pagamentos/');
  }

  static bool _hasHeader(Map<String, dynamic> headers, String name) {
    for (final key in headers.keys) {
      if (key.toLowerCase() == name.toLowerCase()) return true;
    }
    return false;
  }

  static String _newIdempotencyKey() {
    final bytes =
        List<int>.generate(16, (_) => _idempotencyRandom.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

final paymentApiClientProvider = Provider<PaymentApiClient>(
  (ref) => PaymentApiClient(),
);
