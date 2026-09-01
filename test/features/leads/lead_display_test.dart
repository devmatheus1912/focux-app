import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/leads/utils/lead_display.dart';

void main() {
  test('leadOrigemLabel não inventa origem', () {
    expect(leadOrigemLabel(null), 'Não informada');
    expect(leadOrigemLabel('  '), 'Não informada');
    expect(leadOrigemLabel('Instagram'), 'Instagram');
    expect(leadOrigemValues, containsAll(['Instagram', 'WhatsApp', 'Outro']));
    expect(leadNovoHubSubtitle(), 'Cadastre um prospect no CRM');
  });

  test('leadStatus e conversão', () {
    expect(leadStatusLabel('LEAD'), 'Lead');
    expect(leadStatusLabel('INADIMPLENTE'), 'Inadimplente');
    expect(leadStatusLabel('CONVERTIDO'), 'Convertido');
    expect(leadStatusLabel(''), 'Sem status');
    expect(leadPodeConverter('LEAD'), isTrue);
    expect(leadPodeConverter('ATIVO'), isFalse);
    expect(leadPodeConverter('CONVERTIDO'), isFalse);
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
}
