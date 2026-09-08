/// Resolve a rota do toque FCM a partir de `message.data`.
///
/// Usa `route` quando vem no payload. Sem rota, cai nos `type` já
/// contratados — não inventa tipo novo.
String? resolveFcmTapRoute(Map<String, dynamic> data) {
  var route = _asRoute(data['route']);
  route ??= _fallbackByType(data);
  if (route == null) {
    final chatId = _asToken(data['chatId']);
    final alunoId = _asToken(data['alunoId']);
    if (chatId != null) {
      route = '/alunos/$chatId/chat';
    } else if (alunoId != null) {
      route = '/alunos/$alunoId';
    }
  }

  final execucaoId = _asToken(data['execucaoId']);
  if (execucaoId != null &&
      (route == null ||
          route == '/dashboard/aluno' ||
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
    'treino' ||
    'engajamento' ||
    'upsell' ||
    'automacao' ||
    'winback' ||
    'coach' => '/dashboard/aluno',
    'chat' => '/chat/aluno',
    'anamnese' => '/aluno/anamnese',
    'plan_sync' || 'trial_expired' || 'trial' => '/assinatura',
    'retencao' => '/retencao',
    _ => null,
  };
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
