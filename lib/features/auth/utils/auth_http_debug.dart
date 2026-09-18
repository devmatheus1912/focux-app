import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/env.dart';

/// Logs de diagnóstico para fluxos de auth (nunca imprime tokens).
void logAuthApiUrl(String tag) {
  debugPrint('[$tag] Env.apiUrl=${Env.apiUrl}');
}

void logAuthHttpCall(
  String tag, {
  required String path,
  required String method,
  bool? isAluno,
  bool? hasPersonalSlug,
  int? identityTokenLen,
}) {
  debugPrint(
    '[$tag] BEFORE $method $path apiUrl=${Env.apiUrl}'
    '${isAluno == null ? '' : ' isAluno=$isAluno'}'
    '${hasPersonalSlug == null ? '' : ' hasPersonalSlug=$hasPersonalSlug'}'
    '${identityTokenLen == null ? '' : ' identityTokenLen=$identityTokenLen'}',
  );
}

void logAuthHttpError(String tag, Object error, {String? path}) {
  if (error is DioException) {
    debugPrint(
      '[$tag] AFTER statusCode=${error.response?.statusCode} '
      'type=${error.type.name} '
      'path=${path ?? error.requestOptions.path} '
      'apiUrl=${Env.apiUrl} '
      'body=${error.response?.data}',
    );
    return;
  }
  debugPrint('[$tag] AFTER apiUrl=${Env.apiUrl} error=$error');
}

void logAuthHttpOk(String tag, {required String path, int? statusCode}) {
  debugPrint(
    '[$tag] AFTER ok statusCode=${statusCode ?? 200} '
    'path=$path apiUrl=${Env.apiUrl}',
  );
}
