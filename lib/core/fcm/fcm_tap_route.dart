/// Resolve a rota do toque FCM a partir de `message.data`.
///
/// Usa `route` quando vem no payload. Sem rota, cai nos `type` já
/// contratados — não inventa tipo novo.
/// Rotas de personal (`/alunos/…`) não ficam no caminho do aluno.
String? resolveFcmTapRoute(Map<String, dynamic> data) {
  var route = _asRoute(data['route']);
  route ??= _fallbackByType(data);
  if (route == null) {
    final chatId = _asToken(data['chatId']);
    final alunoId = _asToken(data['alunoId']);
    if (chatId != null) {
      route = '/chat/aluno';
    } else if (alunoId != null) {
      route = '/dashboard/aluno';
    }
  }

  route = _sanitizeAlunoFacingRoute(route, data);

  final execucaoId = _asToken(data['execucaoId']);
  if (execucaoId != null &&
      (route == null ||
          route == '/dashboard/aluno' ||
          route == '/checkin/treinos' ||
          route == '/checkin/historico')) {
    route = '/checkin/historico/$execucaoId';
  }

  if (route == null || !route.startsWith('/') || route.startsWith('//')) {
    return null;
  }
  return route;
}

String? _fallbackByType(Map<String, dynamic> data) {
  final type = (data['type'] ?? data['tipo'])?.toString().trim().toLowerCase();
  return switch (type) {
    'mensalidade' || 'dunning' => '/financeiro/aluno',
    'treino' => '/checkin/treinos',
    'engajamento' ||
    'upsell' ||
    'automacao' ||
    'winback' ||
    'coach' ||
    'broadcast' => '/dashboard/aluno',
    'chat' => '/chat/aluno',
    'anamnese' => '/aluno/anamnese',
    'plan_sync' || 'trial_expired' || 'trial' => '/assinatura',
    'retencao' => '/retencao',
    _ => null,
  };
}

/// Push do aluno não deve abrir hub do personal.
String? _sanitizeAlunoFacingRoute(String? route, Map<String, dynamic> data) {
  if (route == null) return null;
  if (route.startsWith('/alunos/')) {
    return _fallbackByType(data) ?? '/dashboard/aluno';
  }
  if (route == '/financeiro') return '/financeiro/aluno';
  if (route == '/chat/inbox') return '/chat/aluno';
  if (route == '/dashboard/personal' || route == '/dashboard') {
    return '/dashboard/aluno';
  }
  return route;
}

String? _asRoute(Object? raw) {
  final value = raw?.toString().trim();
  if (value == null || value.isEmpty) return null;
  return value;
}

String? _asToken(Object? raw) {
  final value = raw?.toString().trim();
  if (value == null || value.isEmpty) return null;
  return value;
}
