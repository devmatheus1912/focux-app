import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';


String _routerSources() {
  final routes = readRouterSourceBundle();
  final redirect =
      File('lib/core/router/app_router_redirect.dart').readAsStringSync();
  return '$routes\n$redirect';
}

void main() {
  test('router keeps logged route aliases and fallback registered', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    final routes = readRouterSourceBundle();

    for (final path in [
      '/',
      '/home',
      '/dashboard',
      '/dashboard/home',
      '/dashboard/personal',
      '/dashboard/aluno',
      '/aluno',
      '/personal',
      '/ia',
      '/ia/copiloto',
    ]) {
      expect(routes, contains("path: '$path'"));
    }

    expect(
      router,
      contains('errorBuilder: (context, state) => const HomeRedirectScreen()'),
    );
  });

  test('router protects direct opens that miss required extra payloads', () {
    final sources = _routerSources();

    expect(sources, contains("path: '/alunos/:id/editar'"));
    expect(sources, contains("state.extra is Aluno"));
    expect(sources, contains("path: '/perfil/editar'"));
    expect(sources, contains("state.extra is PerfilPersonal"));
    expect(sources, contains("path: '/checkin/executar'"));
    expect(sources, contains('treinoIdFromState(state) == null'));
    expect(sources, contains("state.uri.queryParameters['treinoId']"));
    expect(sources, contains('stringRouteExtra(state)'));

    expect(sources, isNot(contains('state.extra as int')));
    expect(sources, isNot(contains('state.extra as String?')));
    expect(sources, isNot(contains("path: '/alunos/:id/alimentar'")));
    expect(sources, isNot(contains('PlanoAlimentar')));
  });

  test('router protects dynamic id paths from invalid ids', () {
    final sources = _routerSources();

    expect(sources, contains('int? intPathParam'));
    expect(sources, contains("intPathParam(state, 'id') == null"));
    expect(sources, contains("int.tryParse(value ?? '')"));

    expect(sources, isNot(contains("int.parse(state.pathParameters['id']!")));
  });

  test('router guards private deep links without a stored session', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    final redirect =
        File('lib/core/router/app_router_redirect.dart').readAsStringSync();

    expect(
      router,
      contains('redirect: (context, state) async => authRedirect(state)'),
    );
    expect(
      router,
      contains('refreshListenable: SessionInvalidator.listenable'),
    );
    expect(redirect, contains('Future<String?> authRedirect'));
    expect(redirect, contains('SecureStorage.getToken()'));
    expect(redirect, contains('SecureStorage.getRequiresPasswordChange()'));
    expect(redirect, contains('passwordChangeRedirect'));
    expect(
      redirect,
      contains("return from.isEmpty ? '/login' : '/login?from=\$from'"),
    );
    expect(redirect, contains('bool isPublicLocation'));

    for (final publicPath in [
      '/',
      '/home',
      '/dashboard',
      '/dashboard/home',
      '/login',
      '/register',
      '/register/aluno',
      '/onboarding',
      '/esqueci-senha',
      '/resetar-senha',
    ]) {
      expect(redirect, contains("path == '$publicPath'"));
    }
    expect(redirect, contains("path.startsWith('/resetar-senha/')"));
    expect(redirect, contains("path.startsWith('/p/')"));
    expect(redirect, contains("path.startsWith('/convite/')"));
    expect(router, isNot(contains("path == '/ia'")));
    expect(router, isNot(contains("path == '/aluno'")));
    expect(router, isNot(contains("path == '/personal'")));
  });

  test('safe navigation provides fallback for direct opened screens', () {
    final helper =
        File('lib/core/router/safe_navigation.dart').readAsStringSync();
    final checkin =
        File(
          'lib/features/checkin/screens/checkin_screen.dart',
        ).readAsStringSync();
    final copilot = readScreenSourceBundle(
      'lib/features/ia/screens/ia_copiloto_screen.dart',
    );
    final chat =
        File(
          'lib/features/chat/screens/conversation_screen.dart',
        ).readAsStringSync();

    expect(helper, contains('void safePopOrGo'));
    expect(helper, contains('context.canPop()'));
    expect(helper, contains('context.go(fallbackLocation)'));
    expect(helper, contains('void safePopOr'));
    expect(checkin, contains("safePopOrGo(context, '/checkin/treinos')"));
    // Copiloto é tab do shell — sem seta/safePop (showBack: false).
    expect(copilot, contains("showBack: false"));
    expect(copilot, isNot(contains('safePopOr(')));
    expect(
      chat,
      contains("_isAlunoMode ? '/dashboard/aluno' : '/dashboard/personal'"),
    );
  });

  test('operational screens use safe fallback navigation', () {
    final alertas =
        File(
          'lib/features/alertas/screens/alertas_screen.dart',
        ).readAsStringSync();
    final financeiro =
        File(
          'lib/features/financeiro/screens/financeiro_screen.dart',
        ).readAsStringSync();
    final leadsKanban =
        File(
          'lib/features/leads/screens/leads_kanban_screen.dart',
        ).readAsStringSync();
    final leadDetail = readScreenSourceBundle(
      'lib/features/leads/screens/lead_detail_screen.dart',
    );
    final assinatura =
        File(
          'lib/features/assinatura/screens/assinatura_screen.dart',
        ).readAsStringSync();
    final avaliacao =
        File(
          'lib/features/avaliacao/screens/evolucao_comparativo_screen.dart',
        ).readAsStringSync();

    // /agenda é tab do shell (FocuxNavigation.shellTabPaths) — sem back para a
    // Home; o fallback dela é coberto em 'residual back controls'.
    expect(alertas, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(financeiro, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(leadsKanban, contains("safePopOrGo(context, '/leads')"));
    expect(leadDetail, contains("safePopOrGo(context, '/leads')"));
    expect(assinatura, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(
      avaliacao,
      contains("safePopOrGo(context, '/alunos/\${widget.alunoId}')"),
    );
  });

  test('residual back controls keep safe fallbacks', () {
    final featureGate =
        File('lib/core/widgets/feature_gate.dart').readAsStringSync();
    final alunosList = readScreenSourceBundle(
      'lib/features/alunos/screens/alunos_list_screen.dart',
    );
    final alunosChromeRoutes =
        File('lib/core/router/app_router_chrome_routes.dart').readAsStringSync();
    final exerciciosList =
        File(
          'lib/features/exercicios/screens/exercicios_list_screen.dart',
        ).readAsStringSync();
    final identidade =
        File(
          'lib/features/perfil/screens/identidade_visual_screen.dart',
        ).readAsStringSync();
    final agendaNovo =
        File(
          'lib/features/agenda/screens/novo_agendamento_screen.dart',
        ).readAsStringSync();
    final avaliacao =
        File(
          'lib/features/avaliacao/screens/evolucao_comparativo_screen.dart',
        ).readAsStringSync();

    expect(
      featureGate,
      contains('safePopOr(context, () => goToRoleHome(context, ref))'),
    );
    expect(alunosList, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(
      alunosChromeRoutes,
      contains("path: '/alunos/acoes-massa'"),
    );
    expect(
      alunosChromeRoutes,
      contains("redirect: (context, state) => '/alunos'"),
    );
    expect(
      alunosChromeRoutes,
      isNot(contains('AcoesMassaScreen')),
    );
    expect(
      exerciciosList,
      contains("safePopOrGo(context, '/treinos')"),
    );
    expect(identidade, contains("safePopOrGo(context, '/perfil')"));
    expect(agendaNovo, contains("safePopOrGo(context, '/agenda')"));
    expect(
      avaliacao,
      contains("safePopOrGo(context, '/alunos/\${widget.alunoId}')"),
    );
  });
}
