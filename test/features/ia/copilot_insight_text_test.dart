import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/copilot_insight_text.dart';

void main() {
  test('texto plano em descricao', () {
    expect(
      copilotInsightDetalhe({'descricao': 'Priorize mobilidade de quadril.'}),
      'Priorize mobilidade de quadril.',
    );
  });

  test('JSON com insights[] extrai descricao legivel', () {
    const blob =
        '{"insights":[{"titulo":"Insight 1","tipo":"treino","descricao":"Aumente volume de pernas em 10%."}]}';
    expect(
      copilotInsightDetalhe({'descricao': blob}),
      'Aumente volume de pernas em 10%.',
    );
    expect(
      copilotInsightTipo({'descricao': blob}),
      'treino',
    );
  });

  test('JSON invalido usa fallback amigavel', () {
    expect(
      copilotInsightDetalhe({'descricao': '{"insights":[{broken'}),
      copilotInsightFallback,
    );
  });

  test('titulo generico vira Recomendacao N', () {
    expect(
      copilotInsightTitulo({'titulo': 'Insight 3'}, 2),
      'Recomendação 3',
    );
  });
}
