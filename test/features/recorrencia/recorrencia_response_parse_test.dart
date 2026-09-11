import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/recorrencia/data/recorrencia_repository.dart';

void main() {
  group('recorrenciaResponseMap', () {
    test('retorna null para null, string null e tipos inválidos', () {
      expect(recorrenciaResponseMap(null), isNull);
      expect(recorrenciaResponseMap('null'), isNull);
      expect(recorrenciaResponseMap('NULL'), isNull);
      expect(recorrenciaResponseMap(''), isNull);
      expect(recorrenciaResponseMap('  '), isNull);
      expect(recorrenciaResponseMap('qualquer'), isNull);
      expect(recorrenciaResponseMap([1, 2]), isNull);
      expect(recorrenciaResponseMap(42), isNull);
    });

    test('aceita Map e converte para Map<String, dynamic>', () {
      final map = recorrenciaResponseMap({
        'id': 1,
        'alunoId': 2,
        'valor': 99.9,
        'status': 'ATIVA',
      });
      expect(map, isNotNull);
      expect(map!['id'], 1);
      expect(map['status'], 'ATIVA');
    });
  });
}
