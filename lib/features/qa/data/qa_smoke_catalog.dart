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
  });

  final String id;
  final String area;
  final String method;
  final String path;
  final String authMode;
  final int expectedAnonymousStatus;

  bool get isPublic => authMode == 'PUBLIC';
}

const qaSmokeRoutes = <QaSmokeRoute>[
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
    label: 'Cadastro aluno por landing/convite',
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
    id: 'public-landing',
    area: 'landing',
    label: 'Landing publica white-label',
    path: '/p/personal-demo',
    authMode: 'PUBLIC',
  ),
  QaSmokeRoute(
    id: 'personal-home',
    area: 'personal',
    label: 'Dashboard personal',
    path: '/dashboard/personal',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fdashboard%2Fpersonal',
  ),
  QaSmokeRoute(
    id: 'personal-financeiro',
    area: 'personal',
    label: 'Financeiro',
    path: '/financeiro',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Ffinanceiro',
  ),
  QaSmokeRoute(
    id: 'personal-chat',
    area: 'chat',
    label: 'Chat inbox',
    path: '/chat/inbox',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fchat%2Finbox',
  ),
  QaSmokeRoute(
    id: 'personal-copilot',
    area: 'ia',
    label: 'IA copiloto',
    path: '/ia/copiloto',
    authMode: 'PERSONAL',
    expectedAnonymousRedirect: '/login?from=%2Fia%2Fcopiloto',
  ),
  QaSmokeRoute(
    id: 'personal-notifications',
    area: 'notificacoes',
    label: 'Central de notificacoes',
    path: '/notificacoes',
    authMode: 'PERSONAL_OR_ALUNO',
    expectedAnonymousRedirect: '/login?from=%2Fnotificacoes',
  ),
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
];

const qaSmokeEndpoints = <QaSmokeEndpoint>[
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
  QaSmokeEndpoint(
    id: 'public-landing',
    area: 'landing',
    method: 'GET',
    path: '/api/public/personal/{slug}',
    authMode: 'PUBLIC',
    expectedAnonymousStatus: 200,
  ),
  QaSmokeEndpoint(
    id: 'public-landing-event',
    area: 'landing',
    method: 'POST',
    path: '/api/public/personal/{slug}/eventos',
    authMode: 'PUBLIC',
    expectedAnonymousStatus: 200,
  ),
  QaSmokeEndpoint(
    id: 'profile',
    area: 'personal',
    method: 'GET',
    path: '/api/personal/perfil',
    authMode: 'PERSONAL',
    expectedAnonymousStatus: 403,
  ),
  QaSmokeEndpoint(
    id: 'command-center',
    area: 'personal',
    method: 'GET',
    path: '/api/dashboard/command-center',
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
    path: '/api/treinos',
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
];

List<QaSmokeRoute> get qaPublicRoutes =>
    qaSmokeRoutes.where((route) => route.isPublic).toList(growable: false);

List<QaSmokeRoute> get qaPrivateRoutes =>
    qaSmokeRoutes.where((route) => route.isPrivate).toList(growable: false);

List<QaSmokeEndpoint> get qaPublicEndpoints =>
    qaSmokeEndpoints
        .where((endpoint) => endpoint.isPublic)
        .toList(growable: false);
