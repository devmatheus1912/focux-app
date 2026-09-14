import '../router/app_router_redirect.dart';

/// Resolve a rota do toque FCM a partir de `message.data`.
///
/// Usa `route` quando vem no payload. Sem rota, cai nos `type` já
/// contratados — não inventa tipo novo.
/// Rotas de personal (`/alunos/…`, hubs operacionais) não ficam no caminho
/// do aluno. Passe [role] quando conhecido para não reescrever push do personal.
String? resolveFcmTapRoute(Map<String, dynamic> data, {String? role}) {
  var route = _asRoute(data['route']);
  route ??= _fallbackByType(data, role: role);
  if (route == null) {
    final chatId = _asToken(data['chatId']);
    final alunoId = _asToken(data['alunoId']);
    if (chatId != null) {
      route = role == 'PERSONAL' ? '/chat/inbox' : '/chat/aluno';
    } else if (alunoId != null) {
      route = role == 'PERSONAL' ? '/alunos/$alunoId' : '/dashboard/aluno';
    }
  }

  route = _sanitizeAlunoFacingRoute(route, data, role: role);

  final execucaoId = _asToken(data['execucaoId']);
  final treinoId = _asToken(data['treinoId']);
  final type = (data['type'] ?? data['tipo'])?.toString().trim().toLowerCase();
  if (treinoId != null &&
      type == 'treino' &&
      (route == null ||
          route == '/checkin/treinos' ||
          route == '/dashboard/aluno')) {
    route = '/checkin/executar?treinoId=$treinoId';
  } else if (execucaoId != null &&
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

String? _fallbackByType(Map<String, dynamic> data, {String? role}) {
  final type = (data['type'] ?? data['tipo'])?.toString().trim().toLowerCase();
  if (role == 'PERSONAL') {
    return switch (type) {
      'mensalidade' || 'dunning' => '/financeiro',
      'chat' => '/chat/inbox',
      'plan_sync' || 'trial_expired' || 'trial' => '/assinatura',
      'retencao' => '/retencao',
      _ => null,
    };
  }
  final treinoId = _asToken(data['treinoId']);
  return switch (type) {
    'mensalidade' || 'dunning' => '/financeiro/aluno',
    'treino' =>
      treinoId == null
          ? '/checkin/treinos'
          : '/checkin/executar?treinoId=$treinoId',
    'engajamento' ||
    'upsell' ||
    'automacao' ||
    'winback' ||
    'coach' ||
    'broadcast' ||
    'retencao' => '/dashboard/aluno',
    'chat' => '/chat/aluno',
    'anamnese' => '/aluno/anamnese',
    'plan_sync' || 'trial_expired' || 'trial' => '/assinatura',
    _ => null,
  };
}

/// Push do aluno não deve abrir hub do personal.
String? _sanitizeAlunoFacingRoute(
  String? route,
  Map<String, dynamic> data, {
  String? role,
}) {
  if (route == null) return null;
  // Personal mantém hubs operacionais (ex.: /retencao no toque do personal).
  if (role == 'PERSONAL') return route;

  if (route.startsWith('/alunos/')) {
    return _fallbackByType(data, role: role) ?? '/dashboard/aluno';
  }
  if (route == '/financeiro') return '/financeiro/aluno';
  if (route == '/chat/inbox') return '/chat/aluno';
  if (route == '/dashboard/personal' || route == '/dashboard') {
    return '/dashboard/aluno';
  }
  // Paridade com authRedirect: qualquer hub PERSONAL_ONLY remapeia.
  if (isPersonalOnlyLocation(route)) {
    return _fallbackByType(data, role: role) ?? '/dashboard/aluno';
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
