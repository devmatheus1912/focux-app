import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/leads/data/lead_repository.dart';

void main() {
  test('Lead.fromJson aceita nulos e datas curtas', () {
    final lead = Lead.fromJson({
      'id': 3,
      'nome': null,
      'status': null,
      'criadoEm': null,
      'convertidoEm': '2026',
      'proximoContato': '2026-10-03T12:00:00',
    });
    expect(lead.id, 3);
    expect(lead.nome, '');
    expect(lead.status, '');
    expect(lead.criadoEm, '');
    expect(lead.convertidoEm, '2026');
    expect(lead.proximoContato, '2026-10-03');
  });
}
