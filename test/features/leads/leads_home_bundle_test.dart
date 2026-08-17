import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/leads/data/lead_repository.dart';

void main() {
  test('LeadsHomeBundle parses leads list', () {
    final bundle = LeadsHomeBundle.fromJson({
      'leads': [
        {
          'id': 1,
          'nome': 'Ana',
          'status': 'LEAD',
          'criadoEm': '2026-08-16T10:00:00',
        },
      ],
    });
    expect(bundle.leads, hasLength(1));
    expect(bundle.leads.first.nome, 'Ana');
    expect(bundle.leads.first.criadoEm, '2026-08-16');
  });
}
