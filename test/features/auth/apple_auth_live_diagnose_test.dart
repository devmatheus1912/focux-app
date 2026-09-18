import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client_connection_pool.dart';
import 'package:focux_app/core/api/tls_certificate_pinning.dart';
import 'package:focux_app/core/config/env.dart';

/// Live against prod. Opt-in only — default CI must not depend on network.
///
///   ENABLE_LIVE_API_TESTS=1 flutter test test/features/auth/apple_auth_live_diagnose_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final liveEnabled =
      Platform.environment['ENABLE_LIVE_API_TESTS'] == '1' ||
      Platform.environment['ENABLE_LIVE_API_TESTS'] == 'true';

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

    expect(dio.httpClientAdapter, isA<IOHttpClientAdapter>());

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
  }, skip: liveEnabled ? false : 'Set ENABLE_LIVE_API_TESTS=1', timeout: const Timeout(Duration(seconds: 45)));

  test('wrong pin via connectionFactory → unknown + pin', () async {
    final wrong = {'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='};
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = TlsCertificatePinning.baseHttpClient();
        client.connectionFactory = (uri, proxyHost, proxyPort) {
          final host = uri.host;
          final port = uri.hasPort ? uri.port : 443;
          SecureSocket? sock;
          final future = SecureSocket.connect(host, port).then((s) {
            sock = s;
            if (!TlsCertificatePinning.matches(s.peerCertificate, wrong)) {
              s.destroy();
              throw const TlsException('Certificate pin mismatch');
            }
            return s;
          });
          return Future<ConnectionTask<Socket>>.value(
            ConnectionTask.fromSocket(future, () {
              try {
                sock?.destroy();
              } catch (_) {}
            }),
          );
        };
        return client;
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
      expect(e.type, DioExceptionType.unknown);
      expect('${e.error}'.toLowerCase(), contains('pin'));
    }
  }, skip: liveEnabled ? false : 'Set ENABLE_LIVE_API_TESTS=1', timeout: const Timeout(Duration(seconds: 30)));
}
