import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/automacoes/data/automacao_repository.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  test('AutomacoesHomeBundle parses fluxos + templates + optional planoFeatures', () {
    final bundle = AutomacoesHomeBundle.fromJson({
      'fluxos': [
        {
          'id': 1,
          'nome': 'Onboarding 7 dias',
          'descricao': 'Sequência de boas-vindas',
          'triggerTipo': 'ALUNO_CRIADO',
          'ativo': true,
          'templateId': 'ONBOARDING_7D',
        },
      ],
      'templates': [
        {
          'id': 'ONBOARDING_7D',
          'nome': 'Onboarding 7 dias',
          'descricao': 'Sequência de boas-vindas para aluno novo',
          'triggerTipo': 'ALUNO_CRIADO',
        },
      ],
      'planoFeatures': {
        'plano': 'ENTERPRISE',
        'features': {'automacoes': true, 'agenda': true},
      },
    });

    expect(bundle.fluxos, hasLength(1));
    expect(bundle.fluxos.first.nome, 'Onboarding 7 dias');
    expect(bundle.fluxos.first.ativo, isTrue);
    expect(bundle.fluxos.first.templateId, 'ONBOARDING_7D');
    expect(bundle.templates, hasLength(1));
    expect(bundle.templates.first.id, 'ONBOARDING_7D');
    expect(bundle.templates.first.nome, 'Onboarding 7 dias');
    expect(bundle.planoFeatures?.plano, SubscriptionPlan.ENTERPRISE);
    expect(bundle.planoFeatures?.automacoes, isTrue);
  });

  test('AutomacoesHomeBundle tolerates missing lists', () {
    final bundle = AutomacoesHomeBundle.fromJson({});
    expect(bundle.fluxos, isEmpty);
    expect(bundle.templates, isEmpty);
    expect(bundle.planoFeatures, isNull);
  });

  test('AutomacaoLog ignora metadata e aluno', () {
    final log = AutomacaoLog.fromJson({
      'status': 'ATIVO',
      'passoAtual': 2,
      'alunoId': 99,
      'metadata': {'email': 'x@y.com'},
    });
    expect(log.status, 'ATIVO');
    expect(log.passoAtual, 2);
    expect(log.iniciadoEm, isNull);
  });

  test('AutomacaoLog lê iniciadoEm', () {
    final log = AutomacaoLog.fromJson({
      'status': 'ATIVO',
      'passoAtual': 0,
      'iniciadoEm': '2026-09-08T12:00:00',
    });
    expect(log.iniciadoEm, '2026-09-08T12:00:00');
  });

  test('AutomacaoLog lê entregas e erro', () {
    final log = AutomacaoLog.fromJson({
      'status': 'ERRO',
      'passoAtual': 1,
      'erro': 'Provedor recusou o envio',
      'entregasOk': 1,
      'entregasFalha': 3,
    });
    expect(log.erro, 'Provedor recusou o envio');
    expect(log.entregasOk, 1);
    expect(log.entregasFalha, 3);
  });

  test('AutomacoesHomeBundle lê page e hasNext', () {
    final bundle = AutomacoesHomeBundle.fromJson({
      'fluxos': [],
      'templates': [],
      'page': 1,
      'hasNext': true,
      'totalFluxos': 40,
    });
    expect(bundle.page, 1);
    expect(bundle.hasNext, isTrue);
    expect(bundle.totalFluxos, 40);
  });
}
