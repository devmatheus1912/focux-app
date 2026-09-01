import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/alunos/screens/alunos_list_screen.dart';
import '../storage/secure_storage.dart';

/// Auth guards and route access helpers for [AppRouter].
Future<String?> authRedirect(GoRouterState state) async {
  final path = state.uri.path;
  final token = (await SecureStorage.getToken())?.trim();
  final hasToken = token != null && token.isNotEmpty;

  // Sessão ativa: sai do funil pré-login (onboarding / login sem return-to).
  if (hasToken &&
      shouldLeavePreLoginGate(path, state.uri.queryParameters)) {
    return homePathForRole(await SecureStorage.getRole());
  }

  if (isPublicLocation(path)) {
    return null;
  }

  if (!hasToken) {
    final from = Uri.encodeComponent(state.uri.toString());
    return from.isEmpty ? '/login' : '/login?from=$from';
  }

  final role = await SecureStorage.getRole();
  if (role == 'ALUNO' && isPersonalOnlyLocation(path)) {
    return '/dashboard/aluno';
  }
  if (role == 'PERSONAL' && isAlunoOnlyLocation(path)) {
    return '/dashboard/personal';
  }

  return null;
}

/// Home da role após login (ou ao pular o gate pré-login com token).
String homePathForRole(String? role) {
  return role == 'ALUNO' ? '/dashboard/aluno' : '/dashboard/personal';
}

/// Com token: `/onboarding` sempre; `/login` só se não houver `from` (deep-link).
bool shouldLeavePreLoginGate(String path, Map<String, String> query) {
  if (path == '/onboarding') return true;
  if (path == '/login' && !query.containsKey('from')) return true;
  return false;
}

bool isPublicLocation(String path) {
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
      path.startsWith('/resetar-senha/') ||
      (kDebugMode && path.startsWith('/qa/'));
}

bool isAlunoOnlyLocation(String path) {
  const alunoOnly = {
    '/dashboard/aluno',
    '/aluno',
    '/aluno/ativacao',
    '/aluno/perfil',
    '/aluno/definir-senha',
    '/evolucao',
    '/chat/aluno',
    '/financeiro/aluno',
    '/feed/aluno',
    '/agenda/aluno',
    '/ia/aluno',
    '/depoimentos-aluno',
    '/checkin/treinos',
    '/checkin/executar',
    '/checkin/historico',
    '/saude',
  };
  return alunoOnly.contains(path);
}

bool isPersonalOnlyLocation(String path) {
  const personalOnly = {
    '/personal',
    '/dashboard/personal',
    '/dashboard/qualidade',
    '/ia',
    '/ia/copiloto',
    '/ia/chat',
    '/ia/checkin',
    '/ia/progressao/aceitar',
    '/alunos',
    '/treinos',
    '/agenda',
    '/agenda/novo',
    '/financeiro',
    '/checkin',
    '/feed',
    '/broadcasts',
    '/leads',
    '/alertas',
    '/relatorios/global',
    '/convites',
    '/perfil',
    '/configuracoes',
    '/perfil/editar',
    '/perfil/wallet',
    '/perfil/ferramentas',
    '/identidade-visual',
    '/white-label',
    '/setup/identidade',
    '/planos',
    '/paywall',
    '/assinatura',
    '/migracao-magica',
    '/growth/migracao',
    '/promo-enterprise',
    '/ranking',
    '/coach',
    '/galeria',
    '/feedback-videos',
    '/busca',
    '/analytics',
    '/admin/rbac',
  };
  if (personalOnly.contains(path)) {
    return true;
  }

  return path.startsWith('/alunos/') ||
      path.startsWith('/treinos/') ||
      path.startsWith('/exercicios') ||
      path.startsWith('/alertas/');
}

String? stringRouteExtra(GoRouterState state) {
  final extra = state.extra;
  return extra is String && extra.trim().isNotEmpty ? extra : null;
}

String? chatAlunoNomeExtra(GoRouterState state) {
  final extra = state.extra;
  if (extra is String && extra.trim().isNotEmpty) return extra;
  if (extra is Map) {
    final nome = extra['nome'];
    if (nome is String && nome.trim().isNotEmpty) return nome;
  }
  return null;
}

String? chatDraftExtra(GoRouterState state) {
  final extra = state.extra;
  if (extra is Map) {
    final draft = extra['draft'];
    if (draft is String && draft.trim().isNotEmpty) return draft;
  }
  return null;
}

int? intPathParam(GoRouterState state, String key) {
  final value = state.pathParameters[key];
  final parsed = int.tryParse(value ?? '');
  return parsed != null && parsed > 0 ? parsed : null;
}

int? treinoIdFromState(GoRouterState state) {
  final extra = state.extra;
  if (extra is int && extra > 0) {
    return extra;
  }
  return int.tryParse(state.uri.queryParameters['treinoId'] ?? '');
}

AlunoFiltro alunoFiltroFromQuery(String? value) {
  return switch (value?.trim().toLowerCase()) {
    'ativos' => AlunoFiltro.ativos,
    'inadimplentes' => AlunoFiltro.inadimplentes,
    'risco' => AlunoFiltro.risco,
    'contato' || 'contato-hoje' || 'contatohoje' => AlunoFiltro.contatoHoje,
    'novos' => AlunoFiltro.novos,
    _ => AlunoFiltro.todos,
  };
}
