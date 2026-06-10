import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/alunos/screens/alunos_list_screen.dart';
import '../storage/secure_storage.dart';

/// Auth guards and route access helpers for [AppRouter].
Future<String?> authRedirect(GoRouterState state) async {
  if (isPublicLocation(state.uri.path)) {
    return null;
  }

  final token = (await SecureStorage.getToken())?.trim();
  if (token == null || token.isEmpty) {
    final from = Uri.encodeComponent(state.uri.toString());
    return from.isEmpty ? '/login' : '/login?from=$from';
  }

  final role = await SecureStorage.getRole();
  final path = state.uri.path;
  if (role == 'ALUNO' && isPersonalOnlyLocation(path)) {
    return '/dashboard/aluno';
  }
  if (role == 'PERSONAL' && isAlunoOnlyLocation(path)) {
    return '/dashboard/personal';
  }

  return null;
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
