import 'package:dio/dio.dart';

import '../api/api_error.dart';

/// Extracts a user-friendly error message from any exception.
/// Strips DioException stack traces, HTTP status details, and raw class names
/// so the user never sees internal technical errors.
String friendlyError(Object error, {String? fallback}) {
  final fb = fallback ?? 'Algo deu errado. Tente novamente.';

  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    // Try to extract a server-provided message. `erro` is the field name in
    // the paired contract; the others stay as tolerance for older payloads.
    if (data is Map) {
      final fieldFriendly = _friendlyValidationDetalhes(data['detalhes']);
      if (fieldFriendly != null) return fieldFriendly;
      final msg =
          data['erro'] ?? data['message'] ?? data['mensagem'] ?? data['error'];
      if (msg is String && msg.trim().isNotEmpty) {
        final humanized = _humanizeServerMessage(msg);
        // Validação genérica sem detalhes → mensagem mais acionável.
        if (statusCode == 400 &&
            (humanized.toLowerCase().contains('validação') ||
                humanized.toLowerCase().contains('validacao'))) {
          return 'Revise os campos destacados e tente de novo.';
        }
        return humanized;
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
        return 'Muitas tentativas. Aguarde e tente de novo.';
      case 500:
        return 'Erro no servidor. Tente novamente em instantes.';
      case 502:
      case 503:
        return 'Servidor indisponível, tente novamente';
    }

    // Network / timeout — only when there was no HTTP status.
    if (statusCode == null) {
      final hay =
          '${error.message ?? ''} ${error.error ?? ''} '
                  '${error.error?.runtimeType ?? ''}'
              .toLowerCase();
      // Pin / badCertificate → copy de segurança. Handshake genérico = rede.
      final isPinOrBadCert =
          error.type == DioExceptionType.badCertificate ||
          hay.contains('certificate pin') ||
          hay.contains('pin mismatch') ||
          hay.contains('certificate_verify_failed') ||
          hay.contains('bad certificate') ||
          (hay.contains('tlsexception') && hay.contains('pin'));
      if (isPinOrBadCert) {
        return 'Falha na conexão segura com o servidor. Atualize o app e tente de novo.';
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Conexão lenta. Verifique sua internet.';
        case DioExceptionType.connectionError:
          return 'Sem conexão com o servidor.';
        case DioExceptionType.cancel:
          return 'Requisição cancelada.';
        case DioExceptionType.unknown:
          if (hay.contains('socket') ||
              hay.contains('failed host lookup') ||
              hay.contains('host lookup') ||
              hay.contains('handshakeexception') ||
              hay.contains('handshake')) {
            return 'Sem conexão com o servidor.';
          }
          break;
        default:
          break;
      }
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

/// Converte `detalhes` de MethodArgumentNotValid (campo → mensagem) em copy PT.
String? _friendlyValidationDetalhes(Object? raw) {
  if (raw is! Map || raw.isEmpty) return null;
  final parts = <String>[];
  for (final entry in raw.entries) {
    final key = entry.key.toString();
    final label = _validationFieldLabel(key);
    final detail = entry.value?.toString().trim() ?? '';
    if (detail.isEmpty) {
      parts.add(label);
      continue;
    }
    final lower = detail.toLowerCase();
    if (lower.contains('size') ||
        lower.contains('between') ||
        lower.contains('length') ||
        lower.contains('máximo') ||
        lower.contains('maximo') ||
        lower.contains('max')) {
      parts.add('$label está longo demais');
    } else if (lower.contains('not blank') ||
        lower.contains('not null') ||
        lower.contains('obrigat')) {
      parts.add('$label é obrigatório');
    } else {
      parts.add('$label: ${_humanizeServerMessage(detail)}');
    }
  }
  if (parts.isEmpty) return null;
  if (parts.length == 1) return parts.first;
  if (parts.length == 2) return '${parts[0]} e ${parts[1]}.';
  return '${parts.take(2).join(', ')} e mais ${parts.length - 2}.';
}

String _validationFieldLabel(String field) {
  const labels = {
    'qualidadeSono': 'Qualidade do sono',
    'nivelEstresse': 'Nível de estresse',
    'tabagismo': 'Tabagismo',
    'alcool': 'Álcool',
    'objetivo': 'Objetivo',
    'objetivoDetalhado': 'Objetivo detalhado',
    'historicoMedico': 'Histórico médico',
    'cirurgias': 'Cirurgias',
    'doresCronicas': 'Dores crônicas',
    'lesoes': 'Lesões',
    'medicamentos': 'Medicamentos',
    'alergias': 'Alergias',
    'gestacaoPosParto': 'Gestação / pós-parto',
    'sintomasCv': 'Sintomas cardiovasculares',
    'observacoes': 'Observações',
    'preferenciasTreino': 'Preferências de treino',
    'restricoesAlimentares': 'Restrições alimentares',
    'historicoAtividade': 'Histórico de atividade',
    'motivoInterrupcoes': 'Motivo de interrupções',
    'motivacaoAtual': 'Motivação atual',
    'algoMais': 'Algo mais',
    'parqOutraRazaoDetalhe': 'Detalhe do PAR-Q+',
    'sonoHoras': 'Horas de sono',
    'disponibilidadeSemanal': 'Disponibilidade',
  };
  return labels[field] ?? field;
}

String _humanizeServerMessage(String raw) {
  final msg = raw.trim();
  if (msg.isEmpty) return 'Algo deu errado. Tente novamente.';

  final lower = msg.toLowerCase();
  if (lower.contains('collector') &&
      (lower.contains('without key') ||
          lower.contains('key enabled') ||
          lower.contains('chave'))) {
    return 'Conta Mercado Pago sem chave PIX ativa. '
        'No app do MP, ative uma chave PIX e tente de novo.';
  }
  if (lower.contains('erro ao gerar pix') && lower.contains('{')) {
    if (lower.contains('without key') || lower.contains('key enabled')) {
      return 'Conta Mercado Pago sem chave PIX ativa. '
          'No app do MP, ative uma chave PIX e tente de novo.';
    }
    return 'Não foi possível gerar o PIX. '
        'Confira o Mercado Pago e o e-mail do aluno.';
  }
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
  // Never dump raw JSON / MP payloads into the sheet.
  if (msg.startsWith('{') || msg.contains('"cause"') || msg.contains('"error"')) {
    return 'Não foi possível gerar o PIX. Tente de novo em instantes.';
  }

  return msg;
}

/// True when the error is a plan/feature gate (not a real outage).
///
/// `codigo` do catálogo decide sozinho e o texto não é consultado. Código
/// fora do catálogo não conclui nada — cai no heurístico de texto, porque
/// código que o backend passou a mandar depois desta versão do app não pode
/// virar "não é gate" e derrubar a sheet de upgrade em silêncio.
///
/// O match de string é o fallback para os pontos de lançamento que ainda não
/// populam o campo (§2.4 do contrato pareado). Enquanto ele existe, reescrever
/// mensagem no servidor quebra o gate sem quebrar nenhum teste.
bool isPlanGateError(Object error) {
  final apiError = ApiError.from(error);
  if (apiError == null) return false;
  final codigo = apiError.codigo;
  if (codigo != null && ApiErrorCodes.isKnown(codigo)) {
    return ApiErrorCodes.planGate.contains(codigo);
  }
  if (apiError.status != 403) return false;
  return _looksLikePlanGateText(apiError.mensagem);
}

/// True quando o teto do plano foi atingido, e não quando o tier não alcança.
///
/// Cota **não** é entitlement (§2 do contrato). Sheet de "desbloqueie o
/// recurso" não abre por isto — IA tem UI própria de cota, aluno-limite
/// mostra a mensagem de `erro`. Sem `codigo` no corpo isto é indistinguível
/// de gate pelo texto, então o fallback devolve `false`.
bool isPlanQuotaError(Object error) {
  final apiError = ApiError.from(error);
  if (apiError == null || !apiError.hasCodigo) return false;
  return ApiErrorCodes.quotaExceeded.contains(apiError.codigo);
}

/// Gate ou cota: não é indisponibilidade. Home que já mostra locked/upsell
/// usa isto para não empilhar snackbar de falha. Não abre paywall — paywall
/// é só [isPlanGateError].
bool isPlanRestrictionError(Object error) =>
    isPlanGateError(error) || isPlanQuotaError(error);

bool _looksLikePlanGateText(String? message) {
  if (message == null) return false;
  final lower = message.toLowerCase();
  return lower.contains('requer plano') ||
      lower.contains('faça upgrade') ||
      lower.contains('faca upgrade') ||
      lower.contains('premium');
}
