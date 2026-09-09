import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/utils/exercicio_detail_display.dart';

void main() {
  test('exercicioHubSubtitle usa só o grupo', () {
    expect(exercicioHubSubtitle(grupo: null), 'Exercício');
    expect(exercicioHubSubtitle(grupo: 'Peito'), 'Peito');
    expect(exercicioHubSubtitle(grupo: '  '), 'Exercício');
    expect(exercicioVideoMetric(hasVideo: true), 'Com vídeo');
    expect(exercicioVideoMetric(hasVideo: false), 'Sem vídeo');
    expect(exercicioDificuldadeHint(null), 'Cadastro');
    expect(exercicioDificuldadeHint('Intermediário'), 'Intermediário');
  });
}
