import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../../core/api/api_error.dart';

/// Mapeia erros do login por e-mail/senha para mensagens amigáveis em pt-BR.
///
/// `codigo` é a fonte primária. Status 401 continua como fallback para
/// backend antigo sem o campo. O texto de `erro` no servidor não é
/// reescrito nem exibido cru.
String mapLoginError(Object error) {
  final api = ApiError.from(error);
  final codigo = api?.codigo;
  if (codigo != null && ApiErrorCodes.credentials.contains(codigo)) {
    return _loginCredenciaisCopy;
  }
  if (error is DioException) {
    final statusCode = error.response?.statusCode ?? api?.status;
    if (statusCode == null) return 'Sem conexão com o servidor.';
    if (statusCode == 401) return _loginCredenciaisCopy;
    if (statusCode == 429) {
      return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
    }
  }
  return 'Não foi possível entrar agora.';
}

const _loginCredenciaisCopy =
    'Email ou senha incorretos. '
    'Se você entrou com Google, use o botão Google ou redefina a senha.';

/// Extrai `message` do body JSON do backend, quando existir.
String? _backendMessage(Object error) {
  if (error is! DioException) return null;
  final body = error.response?.data;
  if (body is Map) {
    for (final key in ['message', 'erro', 'mensagem', 'error']) {
      final raw = body[key];
      if (raw is String) {
        final msg = raw.trim();
        if (msg.isNotEmpty) return _humanizeProxyTimeout(msg);
      }
    }
  }
  if (body is String) {
    final raw = body.trim();
    if (raw.isNotEmpty) return _humanizeProxyTimeout(raw);
  }
  final dioMessage = error.message?.trim();
  if (dioMessage != null && dioMessage.isNotEmpty) {
    return _humanizeProxyTimeout(dioMessage);
  }
  return null;
}

String _humanizeProxyTimeout(String raw) {
  final lower = raw.toLowerCase();
  if (lower.contains('failed to respond') ||
      lower.contains('application failed') ||
      lower.contains('gateway timeout') ||
      lower.contains('service unavailable')) {
    return 'Servidor indisponível no momento. Tente de novo em instantes.';
  }
  return raw;
}

/// Pedido de código para recuperar senha.
String mapEsqueciSenhaError(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == null) return 'Sem conexão com o servidor.';
    if (statusCode == 429) {
      return _backendMessage(error) ??
          'Muitas tentativas. Aguarde um pouco e tente de novo.';
    }
    if (statusCode == 400) {
      return _backendMessage(error) ??
          'Não foi possível enviar o código. Confira o e-mail e o papel.';
    }
    final msg = _backendMessage(error);
    if (msg != null) return msg;
  }
  return 'Não foi possível enviar o código agora.';
}

/// Validação do código de 6 dígitos no reset de senha.
String mapResetCodigoError(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == null) return 'Sem conexão com o servidor.';
    if (statusCode == 429) {
      return _backendMessage(error) ??
          'Muitas tentativas. Aguarde e peça um novo código.';
    }
    if (statusCode == 400) {
      return _backendMessage(error) ?? 'Código inválido ou expirado.';
    }
    final msg = _backendMessage(error);
    if (msg != null) return msg;
  }
  return 'Código inválido ou expirado.';
}

/// Confirmação da nova senha após o OTP.
String mapResetSenhaError(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == null) return 'Sem conexão com o servidor.';
    if (statusCode == 429) {
      return _backendMessage(error) ??
          'Muitas tentativas. Aguarde um pouco e tente de novo.';
    }
    if (statusCode == 400) {
      return _backendMessage(error) ??
          'Código ou senha recusados. Solicite um novo código se expirou.';
    }
    final msg = _backendMessage(error);
    if (msg != null) return msg;
  }
  return 'Código ou senha recusados. Solicite um novo código se expirou.';
}

/// Troca da senha provisória do aluno após o primeiro login.
String mapDefinirSenhaError(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == null) return 'Sem conexão com o servidor.';
    if (statusCode == 429) {
      return _backendMessage(error) ??
          'Muitas tentativas. Aguarde um pouco e tente de novo.';
    }
    if (statusCode == 401) {
      return 'Senha provisória incorreta. Confira e tente de novo.';
    }
    if (statusCode == 400) {
      return _backendMessage(error) ??
          'A nova senha precisa ter no mínimo 8 caracteres.';
    }
  }
  return 'Não foi possível definir a nova senha. Verifique os dados.';
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
    if (statusCode == 400) {
      return _backendMessage(error) ??
          'Dados inválidos no cadastro com Google. Tente de novo.';
    }
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return _backendMessage(error) ??
          'Servidor indisponível no momento. Tente de novo em instantes.';
    }
    if (statusCode == null) {
      return _backendMessage(error) ?? 'Sem conexão com o servidor.';
    }
    final msg = _backendMessage(error);
    return msg != null && msg.isNotEmpty
        ? msg
        : 'Erro $statusCode no login com Google.';
  }
  if (error is PlatformException) {
    final code = error.code;
    final detail = '${error.message ?? ''} ${error.details ?? ''}'.toLowerCase();
    if (code == 'sign_in_failed' &&
        (detail.contains('10') || detail.contains('developer_error'))) {
      return 'Google Sign-In não está liberado para este APK de release. '
          'No Firebase, cadastre o SHA-1 do keystore de release do app.';
    }
    if (code == 'sign_in_canceled') {
      return 'Login com Google cancelado.';
    }
  }
  if (error is StateError) {
    if (error.message == 'PERSONAL_SLUG_REQUIRED') {
      return 'Abra o link do seu personal (?p=slug) para entrar com Google como aluno.';
    }
    return 'Google não retornou o token de acesso. Verifique a configuração do app.';
  }
  return 'Não foi possível entrar com Google agora.';
}
