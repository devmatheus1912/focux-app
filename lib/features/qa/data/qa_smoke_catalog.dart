class QaSmokeRoute {
  const QaSmokeRoute({
    required this.id,
    required this.area,
    required this.label,
    required this.path,
    required this.authMode,
    this.expectedAnonymousRedirect,
  });

  final String id;
  final String area;
  final String label;
  final String path;
  final String authMode;
  final String? expectedAnonymousRedirect;

  bool get isPublic => authMode == 'PUBLIC';
  bool get isPrivate => authMode != 'PUBLIC';
}

class QaSmokeEndpoint {
  const QaSmokeEndpoint({
    required this.id,
    required this.area,
    required this.method,
    required this.path,
    required this.authMode,
    required this.expectedAnonymousStatus,
    this.queryParameters,
  });

  final String id;
  final String area;
  final String method;
  final String path;
  final String authMode;
  final int expectedAnonymousStatus;
  final Map<String, String>? queryParameters;

  bool get isPublic => authMode == 'PUBLIC';
}

// ═════════════════════════════════════════════════════════════════════════════
// FASE 1: Expanded smoke catalog covering ALL critical routes
// From 13 → 50+ routes covering every module
// ═════════════════════════════════════════════════════════════════════════════

const qaSmokeRoutes = <QaSmokeRoute>[
  // ── Auth (Public) ──────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'public-login',
    area: 'auth',
    label: 'Login',
    path: '/login',
    authMode: 'PUBLIC',
  ),
  QaSmokeRoute(
    id: 'public-login-from-financeiro',
    area: 'auth',
    label: 'Login com retorno seguro',
    path: '/login?from=%2Ffinanceiro',
    authMode: 'PUBLIC',
  ),
  QaSmokeRoute(
    id: 'public-register',
    area: 'auth',
    label: 'Cadastro personal',
    path: '/register',
    authMode: 'PUBLIC',
  ),
  QaSmokeRoute(
    id: 'public-student-register',
    area: 'auth',
    label: 'Cadastro aluno por convite',
    path: '/register/aluno?p=personal-demo',
    authMode: 'PUBLIC',
  ),
  QaSmokeRoute(
    id: 'public-password-reset',
    area: 'auth',
    label: 'Recuperacao de senha',
    path: '/esqueci-senha',
    authMode: 'PUBLIC',
  ),
  QaSmokeRoute(
    id: 'public-onboarding',
    area: 'auth',
    label: 'Onboarding intro',
    path: '/onboarding',
    authMode: 'PUBLIC',
  ),

  // ── Personal Dashboard & Core ─────────────────────────────────────────────
  QaSmokeRoute(
    id: 'personal-home',
    area: 'personal',
    label: 'Dashboard personal',
    path: '/dashboard/personal',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fdashboard%2Fpersonal',
  ),
  QaSmokeRoute(
    id: 'personal-perfil',
    area: 'personal',
    label: 'Perfil pessoal',
    path: '/perfil',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fperfil',
  ),
  QaSmokeRoute(
    id: 'personal-configuracoes',
    area: 'personal',
    label: 'Configuracoes',
    path: '/configuracoes',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fconfiguracoes',
  ),

  // ── Alunos ─────────────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'personal-alunos-list',
    area: 'alunos',
    label: 'Lista de alunos',
    path: '/alunos',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Falunos',
  ),
  QaSmokeRoute(
    id: 'personal-add-aluno',
    area: 'alunos',
    label: 'Cadastrar aluno',
    path: '/alunos/novo',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Falunos%2Fnovo',
  ),

  // ── Treinos ────────────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'personal-treinos',
    area: 'treinos',
    label: 'Lista de treinos',
    path: '/treinos',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Ftreinos',
  ),

  // ── Financeiro ─────────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'personal-financeiro',
    area: 'financeiro',
    label: 'Financeiro',
    path: '/financeiro',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Ffinanceiro',
  ),

  // ── Chat ───────────────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'personal-chat',
    area: 'chat',
    label: 'Chat inbox',
    path: '/chat/inbox',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fchat%2Finbox',
  ),

  // ── IA ─────────────────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'personal-copilot',
    area: 'ia',
    label: 'IA copiloto',
    path: '/ia/copiloto',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fia%2Fcopiloto',
  ),
  QaSmokeRoute(
    id: 'personal-checkin-ia',
    area: 'ia',
    label: 'Check-in com IA',
    path: '/ia/checkin',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fia%2Fcheckin',
  ),

  // ── Feed ───────────────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'personal-feed',
    area: 'feed',
    label: 'Feed personal',
    path: '/feed',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Ffeed',
  ),
  QaSmokeRoute(
    id: 'personal-exercicios',
    area: 'exercicios',
    label: 'Biblioteca de exercicios',
    path: '/exercicios',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fexercicios',
  ),
  QaSmokeRoute(
    id: 'personal-broadcasts',
    area: 'broadcasts',
    label: 'Broadcasts',
    path: '/broadcasts',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fbroadcasts',
  ),
  QaSmokeRoute(
    id: 'personal-suporte',
    area: 'suporte',
    label: 'Suporte Focux',
    path: '/suporte',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fsuporte',
  ),

  // ── Growth ─────────────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'personal-migracao',
    area: 'growth',
    label: 'Migracao Magica',
    path: '/growth/migracao',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fgrowth%2Fmigracao',
  ),

  // ── Notificações ───────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'personal-notifications',
    area: 'notificacoes',
    label: 'Central de notificacoes',
    path: '/notificacoes',
    authMode: 'PERSONAL_OR_ALUNO',
    expectedAnonymousRedirect: '/login?from=%2Fnotificacoes',
  ),

  // ── Analytics ──────────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'personal-analytics',
    area: 'analytics',
    label: 'Analytics dashboard',
    path: '/analytics',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fanalytics',
  ),

  // ── Agenda ─────────────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'personal-agenda',
    area: 'agenda',
    label: 'Agenda',
    path: '/agenda',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fagenda',
  ),

  // ── Gamificação ────────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'personal-gamificacao',
    area: 'gamificacao',
    label: 'Gamificacao',
    path: '/gamificacao',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fgamificacao',
  ),

  // ── Qualidade ──────────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'personal-qualidade',
    area: 'dashboard',
    label: 'Qualidade operacional',
    path: '/dashboard/qualidade',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fdashboard%2Fqualidade',
  ),

  // ── Planos ─────────────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'personal-planos',
    area: 'planos',
    label: 'Planos',
    path: '/planos',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fplanos',
  ),

  // ── Kanban ─────────────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'personal-kanban',
    area: 'kanban',
    label: 'Kanban alunos',
    path: '/kanban',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fkanban',
  ),

  // ── Alertas ────────────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'personal-alertas',
    area: 'alertas',
    label: 'Alertas',
    path: '/alertas',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Falertas',
  ),

  // ── Aluno Side ─────────────────────────────────────────────────────────────
  QaSmokeRoute(
    id: 'student-home',
    area: 'aluno',
    label: 'Dashboard aluno',
    path: '/dashboard/aluno',
    authMode: 'ALUNO',
    expectedAnonymousRedirect: '/login?from=%2Fdashboard%2Faluno',
  ),
  QaSmokeRoute(
    id: 'student-workouts',
    area: 'aluno',
    label: 'Treinos do aluno',
    path: '/checkin/treinos',
    authMode: 'ALUNO',
    expectedAnonymousRedirect: '/login?from=%2Fcheckin%2Ftreinos',
  ),
  QaSmokeRoute(
    id: 'student-feed',
    area: 'aluno',
    label: 'Feed do aluno',
    path: '/feed/aluno',
    authMode: 'ALUNO',
    expectedAnonymousRedirect: '/login?from=%2Ffeed%2Faluno',
  ),
  QaSmokeRoute(
    id: 'student-chat',
    area: 'aluno',
    label: 'Chat do aluno',
    path: '/chat/aluno',
    authMode: 'ALUNO',
    expectedAnonymousRedirect: '/login?from=%2Fchat%2Faluno',
  ),
  QaSmokeRoute(
    id: 'student-evolucao',
    area: 'aluno',
    label: 'Evolucao do aluno',
    path: '/evolucao',
    authMode: 'ALUNO',
    expectedAnonymousRedirect: '/login?from=%2Fevolucao',
  ),
];

// ═════════════════════════════════════════════════════════════════════════════
// EXPANDED ENDPOINT CATALOG
// Covers ALL critical API endpoints for production smoke testing
// ═════════════════════════════════════════════════════════════════════════════

const qaSmokeEndpoints = <QaSmokeEndpoint>[
  // ── Public / Health ────────────────────────────────────────────────────────
  QaSmokeEndpoint(
    id: 'health',
    area: 'infra',
    method: 'GET',
    path: '/api/public/health',
    authMode: 'PUBLIC',
    expectedAnonymousStatus: 200,
  ),
  QaSmokeEndpoint(
    id: 'auth-capabilities',
    area: 'auth',
    method: 'GET',
    path: '/api/auth/capabilities',
    authMode: 'PUBLIC',
    expectedAnonymousStatus: 200,
  ),
  QaSmokeEndpoint(
    id: 'auth-environment',
    area: 'auth',
    method: 'GET',
    path: '/api/auth/environment-status',
    authMode: 'PUBLIC',
    expectedAnonymousStatus: 200,
  ),
  // ── Personal Protected ─────────────────────────────────────────────────────
  QaSmokeEndpoint(
    id: 'profile',
    area: 'personal',
    method: 'GET',
    path: '/api/personal/perfil',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),
  QaSmokeEndpoint(
    id: 'dashboard-home',
    area: 'personal',
    method: 'GET',
    path: '/api/dashboard/home',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),
  QaSmokeEndpoint(
    id: 'notifications',
    area: 'notificacoes',
    method: 'GET',
    path: '/api/notificacoes',
    authMode: 'PERSONAL_OR_ALUNO',
    expectedAnonymousStatus: 403,
  ),
  QaSmokeEndpoint(
    id: 'workouts',
    area: 'treinos',
    method: 'GET',
    path: '/api/treinos/home',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),
  QaSmokeEndpoint(
    id: 'exercises',
    area: 'exercicios',
    method: 'GET',
    path: '/api/exercicios',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),

  // ── Alunos ─────────────────────────────────────────────────────────────────
  QaSmokeEndpoint(
    id: 'alunos-list',
    area: 'alunos',
    method: 'GET',
    path: '/api/alunos',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),
  QaSmokeEndpoint(
    id: 'alunos-create',
    area: 'alunos',
    method: 'POST',
    path: '/api/alunos',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),

  // ── Chat ───────────────────────────────────────────────────────────────────
  QaSmokeEndpoint(
    id: 'chat-inbox',
    area: 'chat',
    method: 'GET',
    path: '/api/chat/inbox',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),
  QaSmokeEndpoint(
    id: 'chat-inbox-search',
    area: 'chat',
    method: 'GET',
    path: '/api/chat/inbox/search',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
    queryParameters: {'q': 'smoke'},
  ),
  QaSmokeEndpoint(
    id: 'chat-inbox-archived',
    area: 'chat',
    method: 'GET',
    path: '/api/chat/inbox/archived',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),
  QaSmokeEndpoint(
    id: 'chat-inbox-unread',
    area: 'chat',
    method: 'GET',
    path: '/api/chat/inbox/unread',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),

  // ── Feed ───────────────────────────────────────────────────────────────────
  QaSmokeEndpoint(
    id: 'feed-list',
    area: 'feed',
    method: 'GET',
    path: '/api/feed',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),
  QaSmokeEndpoint(
    id: 'broadcasts-list',
    area: 'broadcasts',
    method: 'GET',
    path: '/api/broadcasts',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),
  QaSmokeEndpoint(
    id: 'suporte-tickets',
    area: 'suporte',
    method: 'GET',
    path: '/api/suporte/tickets/meus',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),

  // ── Financeiro ─────────────────────────────────────────────────────────────
  QaSmokeEndpoint(
    id: 'financeiro-dashboard',
    area: 'financeiro',
    method: 'GET',
    path: '/api/financeiro/home',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),

  // ── Planos ─────────────────────────────────────────────────────────────────
  QaSmokeEndpoint(
    id: 'planos-me',
    area: 'planos',
    method: 'GET',
    path: '/api/planos/me',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),

  // ── Qualidade ──────────────────────────────────────────────────────────────
  QaSmokeEndpoint(
    id: 'qualidade',
    area: 'dashboard',
    method: 'GET',
    path: '/api/dashboard/qualidade',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),

  // ── Onboarding ─────────────────────────────────────────────────────────────
  QaSmokeEndpoint(
    id: 'onboarding-status',
    area: 'onboarding',
    method: 'GET',
    path: '/api/onboarding/status',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),

  // ── Migracao ───────────────────────────────────────────────────────────────
  QaSmokeEndpoint(
    id: 'migracao-texto',
    area: 'growth',
    method: 'POST',
    path: '/api/v1/migracao/texto',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),
  QaSmokeEndpoint(
    id: 'migracao-preview',
    area: 'growth',
    method: 'POST',
    path: '/api/v1/migracao/preview',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),

  // ── Exportacao ─────────────────────────────────────────────────────────────
  QaSmokeEndpoint(
    id: 'exportacao-dados',
    area: 'exportacao',
    method: 'GET',
    path: '/api/exportacao/dados',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),

  // ── LGPD ───────────────────────────────────────────────────────────────────
  QaSmokeEndpoint(
    id: 'lgpd-export',
    area: 'lgpd',
    method: 'GET',
    path: '/api/lgpd/me/export',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),

  // ── IAP ────────────────────────────────────────────────────────────────────
  QaSmokeEndpoint(
    id: 'iap-verify',
    area: 'iap',
    method: 'POST',
    path: '/api/iap/verify',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),

  // ── Backup ─────────────────────────────────────────────────────────────────
  QaSmokeEndpoint(
    id: 'backup-create',
    area: 'backup',
    method: 'POST',
    path: '/api/backup/create',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),
  QaSmokeEndpoint(
    id: 'backup-list',
    area: 'backup',
    method: 'GET',
    path: '/api/backup/list',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),
];

List<QaSmokeRoute> get qaPublicRoutes =>
    qaSmokeRoutes.where((route) => route.isPublic).toList(growable: false);

List<QaSmokeRoute> get qaPrivateRoutes =>
    qaSmokeRoutes.where((route) => route.isPrivate).toList(growable: false);

List<QaSmokeEndpoint> get qaPublicEndpoints => qaSmokeEndpoints
    .where((endpoint) => endpoint.isPublic)
    .toList(growable: false);
