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
    expect(leadListSubtitle(null), 'Funil de prospects');
    expect(
      leadListSubtitle('há 1 min'),
      'Funil de prospects · há 1 min',
    );
    expect(
      leadCardSubtitle(objetivo: 'Emagrecer', origem: 'Instagram'),
      'Emagrecer',
    );
    expect(leadCardSubtitle(objetivo: '  ', origem: 'Google'), 'Google');
    expect(leadCardSubtitle(origem: null), 'Não informada');
    expect(leadFreeLimitLabel(5), 'Limite de 5 leads atingido no Free.');
    expect(leadFreeLimitLabel(4), '4/5 leads no plano Free.');
  });
}
