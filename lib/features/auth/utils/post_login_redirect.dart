/// Utilidades puras de redirecionamento pós-login.
///
/// Mantêm o allowlist de rotas públicas e privadas usado para validar o
/// parâmetro `from` recebido pelo login antes de redirecionar o usuário,
/// evitando open-redirect para URLs externas ou rotas do papel errado.
library;

/// Retorna `rawFrom` se for uma rota interna segura para `isAluno`, ou `null`
/// caso contrário (URL externa, rota pública ou rota do papel oposto).
String? safePostLoginPath(String rawFrom, {required bool isAluno}) {
  final from = rawFrom.trim();
  if (from.isEmpty ||
      !from.startsWith('/') ||
      from.startsWith('//') ||
      from.contains('://')) {
    return null;
  }

  final uri = Uri.tryParse(from);
  final path = uri?.path ?? '';
  if (path.isEmpty || isPublicAuthPath(path)) return null;

  if (isAluno) {
    return isAlunoPath(path) ? from : null;
  }
  return isPersonalPath(path) ? from : null;
}

bool isPublicAuthPath(String path) {
  return path == '/' ||
      path == '/home' ||
      path == '/dashboard' ||
      path == '/dashboard/home' ||
      path == '/login' ||
      path == '/register' ||
      path == '/register/aluno' ||
      path == '/onboarding' ||
      path == '/esqueci-senha' ||
      path == '/resetar-senha' ||
      path.startsWith('/resetar-senha/');
}

bool isAlunoPath(String path) {
  return path == '/dashboard/aluno' ||
      path == '/aluno/ativacao' ||
      path == '/aluno/perfil' ||
      path == '/aluno/definir-senha' ||
      path == '/chat/aluno' ||
      path == '/financeiro/aluno' ||
      path == '/feed/aluno' ||
      path == '/agenda/aluno' ||
      path == '/ia/aluno' ||
      path == '/depoimentos-aluno' ||
      path == '/gamificacao' ||
      path == '/notificacoes' ||
      path == '/suporte' ||
      path == '/checkin/treinos' ||
      path == '/checkin/executar' ||
      path == '/checkin/historico';
}

bool isPersonalPath(String path) {
  if (path == '/dashboard/personal' ||
      path == '/dashboard/qualidade' ||
      path == '/ia/copiloto' ||
      path == '/ia/chat' ||
      path == '/ia/progressao/aceitar' ||
      path == '/alunos' ||
      path == '/treinos' ||
      path == '/agenda' ||
      path == '/agenda/novo' ||
      path == '/financeiro' ||
      path == '/checkin' ||
      path == '/notificacoes' ||
      path == '/feed' ||
      path == '/broadcasts' ||
      path == '/leads' ||
      path == '/alertas' ||
      path == '/relatorios/global' ||
      path == '/suporte' ||
      path == '/perfil' ||
      path == '/identidade-visual' ||
      path == '/setup/identidade' ||
      path == '/planos' ||
      path == '/paywall' ||
      path == '/assinatura') {
    return true;
  }

  return path.startsWith('/alunos/') ||
      path.startsWith('/treinos/') ||
      path.startsWith('/exercicios') ||
      path.startsWith('/alertas/') ||
      path.startsWith('/avaliacao/') ||
      path.startsWith('/anamnese/');
}
