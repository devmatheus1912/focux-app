import 'package:dio/dio.dart';

/// Mapeia erros do login por e-mail/senha para mensagens amigáveis em pt-BR.
String mapLoginError(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == null) return 'Sem conexão com o servidor.';
    if (statusCode == 401) return 'Email ou senha incorretos.';
  }
  return 'Não foi possível entrar agora.';
}

/// Extrai `message` do body JSON do backend, quando existir.
String? _backendMessage(Object error) {
  if (error is! DioException) return null;
  final body = error.response?.data;
  if (body is Map && body['message'] is String) {
    final msg = (body['message'] as String).trim();
    if (msg.isNotEmpty) return msg;
  }
  if (body is String) {
    final raw = body.trim();
    if (raw.toLowerCase().contains('failed to respond') ||
        raw.toLowerCase().contains('application failed')) {
      return 'Servidor indisponível no momento. Tente de novo em instantes.';
    }
  }
  return null;
}

/// Cadastro personal (e-mail/senha + código).
String mapRegisterError(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == null) return 'Sem conexão com o servidor.';
    if (statusCode == 409) return 'Este e-mail já está em uso.';
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return 'Servidor indisponível no momento. Tente de novo em instantes.';
    }
    if (statusCode == 429) {
      return _backendMessage(error) ??
          'Muitas tentativas. Aguarde um pouco e tente de novo.';
    }
    if (statusCode == 400) {
      return _backendMessage(error) ??
          'Código inválido ou dados incompletos. Confira e tente de novo.';
    }
    final msg = _backendMessage(error);
    if (msg != null) return msg;
  }
  return 'Não foi possível criar a conta agora.';
}

/// Envio do código de verificação no cadastro.
String mapSignupCodeError(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == null) return 'Sem conexão com o servidor.';
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return 'Servidor indisponível no momento. Tente de novo em instantes.';
    }
    if (statusCode == 429) {
      return _backendMessage(error) ??
          'Aguarde um minuto antes de pedir outro código.';
    }
    if (statusCode == 400) {
      return _backendMessage(error) ??
          'Não foi possível enviar o código. Tente de novo ou use Google.';
    }
    final msg = _backendMessage(error);
    if (msg != null) return msg;
  }
  return 'Não foi possível enviar o código agora.';
}

/// Mapeia erros do fluxo de login/cadastro via Google para mensagens em pt-BR.
///
/// Nunca inclui token, e-mail ou payload bruto do erro na mensagem exibida
/// ao usuário — apenas o texto de erro do backend, quando presente.
String mapGoogleSignInError(Object error, {required bool isAluno}) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final body = error.response?.data;
    if (statusCode == 401) {
      return isAluno
          ? 'Este Google não está vinculado a um aluno.'
          : 'Não foi possível validar sua conta Google.';
    }
    if (statusCode == 403) {
      return 'Conta sem permissão para entrar como ${isAluno ? "aluno" : "personal"}.';
    }
    if (statusCode == 503) {
      return 'Google ainda não está configurado neste ambiente. Use e-mail e senha por enquanto.';
    }
    if (statusCode == null) return 'Sem conexão com o servidor.';
    final msg =
        (body is Map && body['message'] is String)
            ? body['message'] as String
            : null;
    return msg != null && msg.isNotEmpty
        ? msg
        : 'Erro $statusCode no login com Google.';
  }
  if (error is StateError) {
    if (error.message == 'PERSONAL_SLUG_REQUIRED') {
      return 'Abra o link do seu personal (?p=slug) para entrar com Google como aluno.';
    }
    return 'Google não retornou o token de acesso. Verifique a configuração do app.';
  }
  return 'Não foi possível entrar com Google agora.';
}
