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
  final role = (await SecureStorage.getRole())?.trim().toUpperCase();
  final isAuthed = token != null && token.isNotEmpty;
  final roleMatches = _roleMatchesEndpoint(role, endpoint.authMode);

  try {
    final response = await dio.request<dynamic>(
      endpoint.path,
      queryParameters: endpoint.queryParameters,
      options: Options(method: endpoint.method, validateStatus: (_) => true),
    );

    final status = response.statusCode ?? 0;
    final expected = _expectedStatus(
      endpoint,
      isAuthed: isAuthed,
      roleMatches: roleMatches,
    );
    final ok = expected.contains(status);

    return QaEndpointResult(
      ok: ok,
      statusCode: status,
      error:
          ok
              ? null
              : _formatEndpointError(
                status: status,
                expected: expected,
                isAuthed: isAuthed,
                role: role,
                roleMatches: roleMatches,
                authMode: endpoint.authMode,
              ),
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

bool _roleMatchesEndpoint(String? role, String authMode) {
  if (authMode == 'PUBLIC') return true;
  final normalized = role?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) return false;

  return switch (authMode) {
    'PERSONAL' => normalized == 'PERSONAL',
    'ALUNO' => normalized == 'ALUNO',
    'PERSONAL_OR_ALUNO' =>
      normalized == 'PERSONAL' || normalized == 'ALUNO',
    _ => true,
  };
}

List<int> _expectedStatus(
  QaSmokeEndpoint endpoint, {
  required bool isAuthed,
  required bool roleMatches,
}) {
  if (!isAuthed) {
    return [endpoint.expectedAnonymousStatus];
  }

  if (!roleMatches) {
    return [403];
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

String _formatEndpointError({
  required int status,
  required List<int> expected,
  required bool isAuthed,
  required String? role,
  required bool roleMatches,
  required String authMode,
}) {
  final base = 'HTTP $status (esperado: ${expected.join(' ou ')})';
  if (!isAuthed) return base;
  if (!roleMatches) {
    final current = role?.trim().isNotEmpty == true ? role! : 'desconhecido';
    return '$base — sessão $current, endpoint exige $authMode';
  }
  return base;
}
