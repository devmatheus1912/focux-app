import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/analytics/amplitude_props.dart';

void main() {
  test('mantém números, booleanos e categorias curtas', () {
    final out = amplitudeSafeProps({
      'count': 3,
      'ms': 120.5,
      'compact': true,
      'plan_id': 'pro',
      'method': 'google',
    });
    expect(out, {
      'count': 3,
      'ms': 120.5,
      'compact': true,
      'plan_id': 'pro',
      'method': 'google',
    });
  });

  test('remove IDs, códigos e e-mail', () {
    final out = amplitudeSafeProps({
      'alunoId': 42,
      'aluno_id': 42,
      'exId': 7,
      'legacy_ids': '1,2',
      'transaction_id': 'GPA.1234',
      'codigo': 'ABC123',
      'email': 'x',
      'source': 'contato@exemplo.com',
    });
    expect(out, isEmpty);
  });

  test('troca IDs numéricos de rota e descarta números longos', () {
    final out = amplitudeSafeProps({
      'route': '/alunos/123/treinos/9',
      'label': 'Ligar 11987654321',
      'texto': 'a' * 81,
      'nulo': null,
      'lista': [1, 2],
    });
    expect(out, {'route': '/alunos/:id/treinos/:id'});
  });
}
