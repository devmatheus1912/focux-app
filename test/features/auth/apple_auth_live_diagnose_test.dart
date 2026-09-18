import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client_connection_pool.dart';
import 'package:focux_app/core/api/tls_certificate_pinning.dart';
import 'package:focux_app/core/config/env.dart';

/// Regressão ao vivo: Dio + validateCertificate + pool (caminho ApiClient)
/// deve chegar no backend — pin errado via connectionFactory não é mais o
/// caminho Dio (isso quebrava Apple com Tipo: unknown no iOS).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ApiClient-like Dio reaches Apple 401 with live pins', () async {
    // ignore: avoid_print
    print('apiUrl=${Env.apiUrl} pins=${Env.apiCertPins}');

    TlsCertificatePinning.installGlobalOverrides();

    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    TlsCertificatePinning.apply(dio);
    configureHttpConnectionPool(dio);

    final adapter = dio.httpClientAdapter;
    expect(adapter, isA<IOHttpClientAdapter>());

    try {
      await dio.post(
        '/api/auth/apple',
        data: {
          'identityToken': 'invalid.jwt.token',
          'role': 'PERSONAL',
        },
      );
      fail('expected 401');
    } on DioException catch (e) {
      // ignore: avoid_print
      print(
        'LIVE type=${e.type} status=${e.response?.statusCode} '
        'error=${e.error}',
      );
      expect(e.response?.statusCode, 401);
      expect(e.type, DioExceptionType.badResponse);
    }
  }, timeout: const Timeout(Duration(seconds: 45)));

  test('wrong pin via validateCertificate → badCertificate', () async {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    final wrong = {'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='};
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: TlsCertificatePinning.baseHttpClient,
      validateCertificate: (cert, host, port) {
        return TlsCertificatePinning.matches(cert, wrong);
      },
    );
    try {
      await dio.post(
        '/api/auth/apple',
        data: {'identityToken': 'x', 'role': 'PERSONAL'},
      );
      fail('wrong pin should fail');
    } on DioException catch (e) {
      // ignore: avoid_print
      print('WRONG_PIN type=${e.type} status=${e.response?.statusCode}');
      expect(e.response?.statusCode, isNull);
      expect(e.type, DioExceptionType.badCertificate);
    }
  }, timeout: const Timeout(Duration(seconds: 30)));
}
