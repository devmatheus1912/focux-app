import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  static const _baseUrl = 'https://focux-backend-production.up.railway.app';

  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
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
                'stacktrace': 'Path: ${e.requestOptions.path}\nMethod: ${e.requestOptions.method}\nResponse: ${e.response?.data}',
              });
            }
          } catch (_) {}
        }
        handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
