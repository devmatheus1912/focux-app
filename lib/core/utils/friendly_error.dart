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
      if (msg is String && msg.trim().isNotEmpty) {
        return _humanizeServerMessage(msg);
      }
    }
    if (data is String && data.trim().isNotEmpty && data.length < 200) {
      return _humanizeServerMessage(data);
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
        return _humanizeServerMessage(
          error.message ?? 'Servidor temporariamente indisponível.',
        );
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
    return _humanizeServerMessage(msg);
  }

  return fb;
}

String _humanizeServerMessage(String raw) {
  final msg = raw.trim();
  if (msg.isEmpty) return 'Algo deu errado. Tente novamente.';

  final lower = msg.toLowerCase();
  if (lower.contains('requer plano') ||
      lower.contains('faça upgrade') ||
      lower.contains('faca upgrade')) {
    return msg;
  }
  if (lower.contains('cloudinary') &&
      lower.contains('nao configurado')) {
    return 'Envio de vídeo indisponível: Cloudinary não está configurado no servidor (CLOUDINARY_CLOUD_NAME, API_KEY e API_SECRET).';
  }
  if (lower.contains('upload') &&
      (lower.contains('indispon') || lower.contains('midia'))) {
    return 'Envio de vídeo falhou no servidor. Confira os logs do backend (Cloudinary, tamanho do arquivo ou rede) e tente de novo.';
  }
  if (lower.contains('service unavailable') || lower.contains('503')) {
    return 'Serviço de mídia temporariamente indisponível. Tente novamente em instantes.';
  }

  return msg;
}

/// True when the error is a plan/feature gate (not a real outage).
bool isPlanGateError(Object error) {
  if (error is! DioException) return false;
  if (error.response?.statusCode != 403) return false;
  final data = error.response?.data;
  String? msg;
  if (data is Map) {
    final raw = data['message'] ?? data['erro'] ?? data['mensagem'];
    if (raw is String) msg = raw;
  } else if (data is String) {
    msg = data;
  }
  if (msg == null) return false;
  final lower = msg.toLowerCase();
  return lower.contains('requer plano') ||
      lower.contains('faça upgrade') ||
      lower.contains('faca upgrade') ||
      lower.contains('premium');
}
