import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/models/ia_progressao_carga_result.dart';

void main() {
  test('fromApi uses structured exercicios when present', () {
    final result = IaProgressaoCargaResult.fromApi({
      'resposta': 'fallback markdown',
      'intro': 'Contexto curto.',
      'footer': 'RPE.',
      'sugestoesRegistradas': 1,
      'exercicios': [
        {
          'exercicio': 'Supino',
          'cargaAtual': '80kg 3x8',
          'cargaSugerida': '82,5kg 3x8',
          'justificativa': 'Progressão segura.',
          'deltaKg': 2.5,
        },
      ],
    });

    expect(result.exercises, hasLength(1));
    expect(result.exercises.first.deltaLabel, '+2,5 kg');
    expect(result.sugestoesRegistradas, 1);
    expect(result.toParsed().hasStructuredRows, isTrue);
  });
}
