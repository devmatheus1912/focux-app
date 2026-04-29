import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('router keeps logged route aliases and fallback registered', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();

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
      expect(router, contains("path: '$path'"));
    }

    expect(
      router,
      contains('errorBuilder: (context, state) => const HomeRedirectScreen()'),
    );
  });

  test('router protects direct opens that miss required extra payloads', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();

    expect(router, contains("path: '/alunos/:id/editar'"));
    expect(router, contains("state.extra is Aluno"));
    expect(router, contains("path: '/perfil/editar'"));
    expect(router, contains("state.extra is PerfilPersonal"));
    expect(router, contains("path: '/checkin/executar'"));
    expect(router, contains("_treinoIdFromState(state) == null"));
    expect(router, contains("state.uri.queryParameters['treinoId']"));
    expect(router, contains("_stringExtra(state)"));

    expect(router, isNot(contains('state.extra as int')));
    expect(router, isNot(contains('state.extra as String?')));
  });

  test('router protects dynamic id paths from invalid ids', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();

    expect(router, contains('int? _intPathParam'));
    expect(router, contains("_intPathParam(state, 'id') == null"));
    expect(router, contains("int.tryParse(value ?? '')"));

    expect(router, isNot(contains("int.parse(state.pathParameters['id']!")));
  });

  test('safe navigation provides fallback for direct opened screens', () {
    final helper = File('lib/core/router/safe_navigation.dart').readAsStringSync();
    final checkin = File('lib/features/checkin/screens/checkin_screen.dart').readAsStringSync();
    final copilot = File('lib/features/ia/screens/ia_copiloto_screen.dart').readAsStringSync();
    final chat = File('lib/features/chat/screens/conversation_screen.dart').readAsStringSync();

    expect(helper, contains('void safePopOrGo'));
    expect(helper, contains('context.canPop()'));
    expect(helper, contains('context.go(fallbackLocation)'));
    expect(helper, contains('void safePopOr'));
    expect(checkin, contains("safePopOrGo(context, '/checkin/treinos')"));
    expect(copilot, contains('safePopOr(context, () => goToRoleHome(context, ref))'));
    expect(chat, contains("_isAlunoMode ? '/dashboard/aluno' : '/dashboard/personal'"));
  });

  test('operational screens use safe fallback navigation', () {
    final agenda = File('lib/features/agenda/screens/agenda_screen.dart').readAsStringSync();
    final alertas = File('lib/features/alertas/screens/alertas_screen.dart').readAsStringSync();
    final financeiro = File('lib/features/financeiro/screens/financeiro_screen.dart').readAsStringSync();
    final leadsKanban = File('lib/features/leads/screens/leads_kanban_screen.dart').readAsStringSync();
    final leadDetail = File('lib/features/leads/screens/lead_detail_screen.dart').readAsStringSync();
    final assinatura = File('lib/features/assinatura/screens/assinatura_screen.dart').readAsStringSync();
    final avaliacao = File('lib/features/avaliacao/screens/avaliacao_screen.dart').readAsStringSync();
    final alimentar = File('lib/features/alimentar/screens/alimentar_screen.dart').readAsStringSync();
    final planoAlimentar = File('lib/features/alimentar/screens/plano_alimentar_detail_screen.dart').readAsStringSync();

    expect(agenda, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(alertas, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(financeiro, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(leadsKanban, contains("safePopOrGo(context, '/leads')"));
    expect(leadDetail, contains("safePopOrGo(context, '/leads')"));
    expect(assinatura, contains("safePopOrGo(context, '/planos')"));
    expect(avaliacao, contains("safePopOrGo(context, '/alunos/\${widget.alunoId}')"));
    expect(alimentar, contains("safePopOrGo(context, '/alunos/\${widget.alunoId}')"));
    expect(planoAlimentar, contains("safePopOrGo(context, '/alunos/\${widget.alunoId}/alimentar')"));
  });

  test('residual back controls keep safe fallbacks', () {
    final featureGate = File('lib/core/widgets/feature_gate.dart').readAsStringSync();
    final alunosList = File('lib/features/alunos/screens/alunos_list_screen.dart').readAsStringSync();
    final acoesMassa = File('lib/features/alunos/screens/acoes_massa_screen.dart').readAsStringSync();
    final exerciciosList = File('lib/features/exercicios/screens/exercicios_list_screen.dart').readAsStringSync();
    final identidade = File('lib/features/perfil/screens/identidade_visual_screen.dart').readAsStringSync();
    final agenda = File('lib/features/agenda/screens/agenda_screen.dart').readAsStringSync();
    final avaliacao = File('lib/features/avaliacao/screens/avaliacao_screen.dart').readAsStringSync();

    expect(featureGate, contains('safePopOr(context, () => goToRoleHome(context, ref))'));
    expect(alunosList, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(acoesMassa, contains("safePopOrGo(context, '/alunos')"));
    expect(exerciciosList, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(identidade, contains("safePopOrGo(context, '/dashboard/personal')"));
    expect(agenda, contains("safePopOrGo(context, '/agenda')"));
    expect(avaliacao, contains("safePopOrGo(context, '/alunos/\${widget.alunoId}')"));
  });
}
