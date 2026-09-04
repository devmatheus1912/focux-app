import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/utils/exercicio_detail_display.dart';

void main() {
  test('exercicioHubSubtitle junta grupo e freshness', () {
    expect(exercicioHubSubtitle(grupo: null), '');
    expect(exercicioHubSubtitle(grupo: 'Peito'), 'Peito');
    expect(
      exercicioHubSubtitle(grupo: 'Peito', freshness: 'Atualizado agora'),
      'Peito · Atualizado agora',
    );
    expect(
      exercicioHubSubtitle(grupo: '  ', freshness: 'Atualizado agora'),
      'Atualizado agora',
    );
  });
}
