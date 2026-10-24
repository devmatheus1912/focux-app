import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_next_actions.dart';

FilaAcaoResumo _ficha({String url = '/alunos/4/rotina?renovar=1&origem=hoje'}) => FilaAcaoResumo(
  tipo: 'FICHA',
  actionKey: 'FICHA_VENCENDO_4',
  titulo: 'Renovar a ficha de Ana',
  descricao: 'Vence em 3 dias',
  acaoUrl: url,
  prioridade: 'P1',
  severidade: 'MEDIA',
  responsavel: 'Personal',
  sla: '7 dias',
  status: 'ABERTO',
  ctaLabel: 'Renovar',
  iaSugerida: false,
);

void main() {
  group('ficha vencendo no Hoje do personal', () {
    test('tocar leva à ficha do aluno com o menu de renovar e a origem hoje', () {
      expect(
        dashboardFilaActionRoute(_ficha()),
        '/alunos/4/rotina?renovar=1&origem=hoje',
      );
    });

    test('a rota não cai nas regras de chat nem de agenda', () {
      final rota = dashboardFilaActionRoute(_ficha());
      expect(rota.contains('/chat'), isFalse);
      expect(rota, isNot('/agenda'));
    });

    test('url que não é rota interna volta para o Hoje', () {
      expect(dashboardFilaActionRoute(_ficha(url: 'https://exemplo.com')), '/dashboard/personal');
    });
  });

  test('a rota da ficha lê renovar e origem da URL', () {
    final rotas = File('lib/core/router/app_router_chrome_routes.dart').readAsStringSync();
    expect(rotas, contains("queryParameters['renovar'] == '1'"));
    expect(rotas, contains("queryParameters['origem']"));
  });
}
