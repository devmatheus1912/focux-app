import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/alunos/screens/alunos_list_screen.dart';
import '../storage/secure_storage.dart';

/// Auth guards and route access helpers for [AppRouter].
Future<String?> authRedirect(GoRouterState state) async {
  final path = state.uri.path;
  final token = (await SecureStorage.getToken())?.trim();
  final hasToken = token != null && token.isNotEmpty;

  if (hasToken) {
    final role = await SecureStorage.getRole();
    final requiresPasswordChange =
        await SecureStorage.getRequiresPasswordChange();
    final forced = passwordChangeRedirect(
      requiresPasswordChange: requiresPasswordChange,
      role: role,
      path: path,
    );
    if (forced != null) return forced;

    // Sessão ativa: sai do funil pré-login (onboarding / login sem return-to).
    if (shouldLeavePreLoginGate(path, state.uri.queryParameters)) {
      return homePathForRole(role);
    }
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

/// Aluno com senha provisória só pode ficar em `/aluno/definir-senha`.
String? passwordChangeRedirect({
  required bool requiresPasswordChange,
  required String? role,
  required String path,
}) {
  if (!requiresPasswordChange || role != 'ALUNO') return null;
  if (path == '/aluno/definir-senha') return null;
  return '/aluno/definir-senha';
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
      path == '/login/mfa' ||
      path == '/register' ||
      path == '/register/aluno' ||
      path == '/onboarding' ||
      path == '/esqueci-senha' ||
      path == '/resetar-senha' ||
      path.startsWith('/resetar-senha/') ||
      path.startsWith('/p/') ||
      path.startsWith('/convite/') ||
      (kDebugMode && path.startsWith('/qa/'));
}

bool isAlunoOnlyLocation(String path) {
  const alunoOnly = {
    '/dashboard/aluno',
    '/aluno',
    '/aluno/ativacao',
    '/aluno/perfil',
    '/aluno/perfil/editar',
    '/aluno/definir-senha',
    '/aluno/anamnese',
    '/aluno/habitos',
    '/aluno/desafios',
    '/aluno/trilhas',
    '/aluno/recorrencia',
    '/aluno/grupo-aulas',
    '/aluno/form-check',
    '/evolucao',
    '/chat/aluno',
    '/financeiro/aluno',
    '/feed/aluno',
    '/agenda/aluno',
    '/depoimentos-aluno',
    '/checkin/treinos',
    '/checkin/executar',
    '/checkin/historico',
    '/saude',
  };
  return alunoOnly.contains(path) ||
      path.startsWith('/checkin/historico/') ||
      path.startsWith('/aluno/desafios/') ||
      path.startsWith('/aluno/habitos/');
}

bool isPersonalOnlyLocation(String path) {
  const personalOnly = {
    '/personal',
    '/dashboard/personal',
    '/dashboard/qualidade',
    '/dashboard/command-center/copiloto',
    '/ia',
    '/ia/copiloto',
    '/ia/chat',
    '/ia/checkin',
    '/ia/progressao/aceitar',
    '/alunos',
    '/kanban',
    '/treinos',
    '/agenda',
    '/agenda/novo',
    '/financeiro',
    '/checkin',
    '/feed',
    '/broadcasts',
    '/leads',
    '/leads-publicos',
    '/alertas',
    '/relatorios/global',
    '/relatorio/business',
    '/convites',
    '/perfil',
    '/configuracoes',
    '/perfil/editar',
    '/perfil/link-publico',
    '/perfil/wallet',
    '/perfil/ferramentas',
    '/perfil/mfa',
    '/perfil/equipe',
    '/perfil/landing-editor',
    '/perfil/white-label',
    '/identidade-visual',
    '/white-label',
    '/setup/identidade',
    '/planos',
    '/paywall',
    '/assinatura',
    '/assinatura/review',
    '/assinatura/success',
    '/migracao-magica',
    '/migracao-focux',
    '/growth/migracao',
    '/promo-enterprise',
    '/ranking',
    '/coach',
    '/galeria',
    '/feedback-videos',
    '/depoimentos',
    '/busca',
    '/analytics',
    '/admin/rbac',
    '/retencao',
    '/dunning',
    '/winback',
    '/ofertas-upsell',
    '/cancel-save',
    '/automacoes',
    '/loja',
    '/pacotes',
    '/recorrencia',
    '/nps',
    '/grupo-aulas',
    '/onboarding/wizard',
    '/referral',
    '/chat/inbox',
    '/desafios',
  };
  if (personalOnly.contains(path)) {
    return true;
  }

  return path.startsWith('/alunos/') ||
      path.startsWith('/personal/alunos/') ||
      path.startsWith('/treinos/') ||
      path.startsWith('/exercicios') ||
      path.startsWith('/financeiro/mensalidades') ||
      path.startsWith('/alertas/') ||
      path.startsWith('/desafios/') ||
      path.startsWith('/habitos') ||
      path.startsWith('/leads/') ||
      path.startsWith('/ferramentas/') ||
      path.startsWith('/treino-presencial/');
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
