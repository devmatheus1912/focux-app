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
}
