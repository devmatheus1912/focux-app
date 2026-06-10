import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import 'qa_smoke_catalog.dart';

class QaEndpointResult {
  const QaEndpointResult({required this.ok, this.statusCode, this.error});

  final bool ok;
  final int? statusCode;
  final String? error;
}

Future<QaEndpointResult> runQaSmokeEndpoint(QaSmokeEndpoint endpoint) async {
  final dio = ApiClient().dio;
  final token = (await SecureStorage.getToken())?.trim();
  final isAuthed = token != null && token.isNotEmpty;

  try {
    final response = await dio.request<dynamic>(
      endpoint.path,
      queryParameters: endpoint.queryParameters,
      options: Options(method: endpoint.method, validateStatus: (_) => true),
    );

    final status = response.statusCode ?? 0;
    final expected = _expectedStatus(endpoint, isAuthed: isAuthed);
    final ok = expected.contains(status);

    return QaEndpointResult(
      ok: ok,
      statusCode: status,
      error: ok ? null : 'HTTP $status (esperado: ${expected.join(' ou ')})',
    );
  } on DioException catch (e) {
    return QaEndpointResult(
      ok: false,
      statusCode: e.response?.statusCode,
      error: e.message ?? e.type.name,
    );
  } catch (e) {
    return QaEndpointResult(ok: false, error: e.toString());
  }
}

List<int> _expectedStatus(QaSmokeEndpoint endpoint, {required bool isAuthed}) {
  if (!isAuthed) {
    return [endpoint.expectedAnonymousStatus];
  }

  if (endpoint.isPublic) {
    return [endpoint.expectedAnonymousStatus, 200];
  }

  // Logado: mutações podem retornar 200/201/202/204/400/422 conforme payload vazio.
  return switch (endpoint.method) {
    'GET' => [200],
    'POST' => [200, 201, 202, 400, 422],
    'DELETE' => [200, 204, 400, 404, 422],
    _ => [200, 201, 202, 204, 400, 422],
  };
}
