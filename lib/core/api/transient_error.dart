import 'package:dio/dio.dart';

/// Sem resposta do servidor por rede ou timeout.
bool isConnectionError(Object error) {
  if (error is! DioException || error.response != null) return false;
  return switch (error.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    _ => false,
  };
}

/// Vale tentar de novo depois; só recusa definitiva (4xx) é final.
bool isTransientApiError(Object error) {
  if (isConnectionError(error)) return true;
  if (error is! DioException) return false;
  final status = error.response?.statusCode ?? 0;
  return status >= 500 || status == 401 || status == 408 || status == 429;
}
