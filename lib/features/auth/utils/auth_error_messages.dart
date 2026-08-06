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
    return 'Google não retornou o token de acesso. Verifique a configuração do app.';
  }
  return 'Não foi possível entrar com Google agora.';
}
