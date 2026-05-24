import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/notificacoes/data/notificacoes_repository.dart';

void main() {
  test('notification model parses evolution notification contract', () {
    final item = NotificacaoApp.fromJson({
      'id': 9,
      'titulo': 'Evolucao registrada',
      'mensagem': 'Carga em Supino: 20 kg -> 22,5 kg',
      'tipo': 'EVOLUCAO',
      'lida': false,
      'route': '/dashboard/aluno',
      'ctaLabel': 'Ver evolucao',
      'dados': {'tipoEvolucao': 'CARGA', 'totalEvolucoes': 2},
      'criadaEm': '2026-04-30T12:20:00',
    });

    expect(item.tipo, 'EVOLUCAO');
    expect(item.lida, isFalse);
    expect(item.route, '/dashboard/aluno');
    expect(item.dados['tipoEvolucao'], 'CARGA');
  });

  test('notification center is routed and visible from dashboards', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    final alunoDashboard = File(
      'lib/features/dashboard/screens/aluno_dashboard_screen.dart',
    ).readAsStringSync();
    final personalDashboard = File(
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/features/notificacoes/screens/notificacoes_screen.dart',
    ).readAsStringSync();
    final repo = File(
      'lib/features/notificacoes/data/notificacoes_repository.dart',
    ).readAsStringSync();

    expect(router, contains("path: '/notificacoes'"));
    expect(alunoDashboard, contains('NotificacaoBadgeButton'));
    expect(personalDashboard, contains('NotificacaoBadgeButton'));
    expect(personalDashboard, contains('notificacoesNaoLidasProvider'));
    expect(screen, contains('Ler todas'));
    expect(repo, contains('/api/notificacoes'));
  });
}
