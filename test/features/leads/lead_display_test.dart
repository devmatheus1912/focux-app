import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/leads/utils/lead_display.dart';

void main() {
  test('leadOrigemLabel não inventa origem', () {
    expect(leadOrigemLabel(null), 'Não informada');
    expect(leadOrigemLabel('  '), 'Não informada');
    expect(leadOrigemLabel('Instagram'), 'Instagram');
    expect(leadOrigemValues, containsAll(['Instagram', 'WhatsApp', 'Outro']));
    expect(leadNovoHubSubtitle(), 'Cadastre um prospect no CRM');
    expect(leadSalvarTooltip(), 'Salvar lead');
    expect(leadConfirmTitle(), 'Salvar este prospect?');
    expect(leadConfirmLabel(), 'Salvar');
    expect(leadConfirmMessage('  '), 'O nome entra no funil de leads.');
    expect(leadConfirmMessage('Ana'), 'Ana entra no funil de leads.');
    expect(leadNomeMax, 100);
    expect(leadTelefoneMax, 20);
  });

  test('leadStatus e conversão', () {
    expect(leadStatusLabel('LEAD'), 'Lead');
    expect(leadStatusLabel('INADIMPLENTE'), 'Inadimplente');
    expect(leadStatusLabel('CONVERTIDO'), 'Convertido');
    expect(leadStatusLabel(''), 'Sem status');
    expect(leadPodeConverter('LEAD'), isTrue);
    expect(leadPodeConverter('ATIVO'), isFalse);
    expect(leadPodeConverter('CONVERTIDO'), isFalse);
    expect(
      leadStickyAction(status: 'LEAD', temTelefone: true),
      LeadStickyAction.converter,
    );
    expect(
      leadStickyAction(status: 'ATIVO', temTelefone: true),
      LeadStickyAction.whatsapp,
    );
    expect(
      leadStickyAction(status: 'CONVERTIDO', temTelefone: false),
      LeadStickyAction.followUp,
    );
    expect(leadStickyP0Label(LeadStickyAction.converter), 'Converter em aluno');
    expect(leadStickyP0Label(LeadStickyAction.whatsapp), 'WhatsApp');
    expect(leadStickyP0Label(LeadStickyAction.followUp), 'Definir follow-up');
    expect(leadStatusDanger('INADIMPLENTE'), isTrue);
    expect(leadStatusDanger('LEAD'), isFalse);
  });

  test('leadInteracao labels em PT-BR', () {
    expect(leadInteracaoTipoLabel('WHATSAPP'), 'WhatsApp');
    expect(leadInteracaoTipoLabel('LIGACAO'), 'Ligação');
    expect(leadInteracaoTipoLabel('EMAIL'), 'E-mail');
    expect(leadInteracaoFxIcon('WHATSAPP'), 'chat');
    expect(leadInteracaoFxIcon('OUTRO'), 'spark');
    expect(leadFollowUpValue(null), 'Não definido');
    expect(leadFollowUpValue('  '), 'Não definido');
  });

  test('lead list chrome helpers', () {
    expect(leadCountLabel(1), '1 lead');
    expect(leadCountLabel(3), '3 leads');
    expect(leadListSubtitle(count: 0), '0 leads');
    expect(
      leadListSubtitle(count: 3, freshness: 'há 1 min'),
      '3 leads · há 1 min',
    );
    expect(leadMatchesQuery(nome: 'Ana Lima', query: 'ana'), isTrue);
    expect(leadMatchesQuery(nome: 'Ana', objetivo: 'Força', query: 'for'), isTrue);
    expect(leadMatchesQuery(nome: 'Ana', query: 'xyz'), isFalse);
    expect(leadListChipStatuses, hasLength(5));
    expect(leadHubSubtitle(status: 'LEAD'), 'Lead');
    expect(leadHubSubtitle(status: 'CONVERTIDO'), 'Convertido');
    expect(
      leadCardSubtitle(objetivo: 'Emagrecer', origem: 'Instagram'),
      'Emagrecer',
    );
    expect(leadCardSubtitle(objetivo: '  ', origem: 'Google'), 'Google');
    expect(leadCardSubtitle(origem: null), 'Não informada');
    expect(leadLimitLabel(5, 5), 'Limite de 5 leads atingido.');
    expect(leadLimitLabel(4, 5), '4/5 leads neste plano.');
    expect(leadShowsLimitBanner(4, limiteLeads: 5), isTrue);
    expect(leadShowsLimitBanner(3, limiteLeads: 5), isFalse);
    expect(leadShowsLimitBanner(4), isFalse);
    expect(leadShowsLimitBanner(9, limiteLeads: 10), isTrue);
    expect(leadInteracoesMetricValue(0), '0');
    expect(leadInteracoesMetricHint(0), 'Nenhum contato registrado');
    expect(leadInteracoesMetricHint(1), '1 contato no histórico');
    expect(leadInteracoesMetricHint(4), '4 contatos no histórico');
  });

  test('lead detalhe conta dias no funil', () {
    expect(leadDiasNoFunilValue('nao-data'), '—');
    expect(
      leadDiasNoFunilValue('2026-09-07', now: DateTime(2026, 9, 7)),
      'Hoje',
    );
    expect(
      leadDiasNoFunilValue('2026-09-01', now: DateTime(2026, 9, 7)),
      '6',
    );
    expect(leadDiasNoFunilHint('2026-09-01'), contains('desde'));
    expect(leadDetailSecoes, hasLength(2));
  });
}
