import 'package:dio/dio.dart';

/// Extracts a user-friendly error message from any exception.
/// Strips DioException stack traces, HTTP status details, and raw class names
/// so the user never sees internal technical errors.
String friendlyError(Object error, {String? fallback}) {
  final fb = fallback ?? 'Algo deu errado. Tente novamente.';

  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    // Try to extract a server-provided message
    if (data is Map<String, dynamic>) {
      final msg =
          data['message'] ?? data['error'] ?? data['erro'] ?? data['mensagem'];
      if (msg is String && msg.trim().isNotEmpty) return msg;
    }
    if (data is String && data.trim().isNotEmpty && data.length < 200) {
      return data;
    }

    // Map common HTTP status codes to friendly messages
    switch (statusCode) {
      case 400:
        return 'Dados inválidos. Verifique e tente novamente.';
      case 401:
        return 'Sessão expirada. Faça login novamente.';
      case 403:
        return 'Sem permissão para acessar este recurso.';
      case 404:
        return 'Recurso não encontrado.';
      case 409:
        return 'Conflito de dados. Tente novamente.';
      case 422:
        return 'Dados incompletos ou inválidos.';
      case 429:
        return 'Muitas tentativas. Aguarde um momento.';
      case 500:
        return 'Erro no servidor. Tente novamente em instantes.';
      case 502:
      case 503:
        return 'Servidor temporariamente indisponível.';
    }

    // Network / timeout
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Conexão lenta. Verifique sua internet.';
      case DioExceptionType.connectionError:
        return 'Sem conexão com o servidor.';
      case DioExceptionType.cancel:
        return 'Requisição cancelada.';
      default:
        break;
    }

    return fb;
  }

  // For non-Dio errors, use the message if short enough
  final msg = error.toString();
  if (msg.length < 100 &&
      !msg.contains('Exception') &&
      !msg.contains('Error:')) {
    return msg;
  }

  return fb;
}
