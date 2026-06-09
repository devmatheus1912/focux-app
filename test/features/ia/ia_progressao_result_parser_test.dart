import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/utils/ia_progressao_result_parser.dart';

void main() {
  const sampleMarkdown = '''
Com base no histórico recente, sugiro progressão controlada na próxima semana.

| Exercício | Carga Atual | Carga Sugerida | Justificativa |
| --- | --- | --- | --- |
| Supino | 80kg 3x8 | 82,5kg 3x8 ou 80kg 3x10 | Aumentar 2,5kg mantendo reps ou manter carga e subir volume. |
| Agachamento | 100kg 4x6 | 102,5kg 4x6 | Progressão linear segura com boa técnica. |

Lembre-se de aquecer e registrar RPE após cada série.
''';

  test('parse markdown table with Supino into structured rows', () {
    final parsed = parseIaProgressaoMarkdown(sampleMarkdown);

    expect(parsed.hasStructuredRows, isTrue);
    expect(parsed.intro, contains('histórico recente'));
    expect(parsed.exercises, hasLength(2));

    final supino = parsed.exercises.first;
    expect(supino.exercicio, 'Supino');
    expect(supino.cargaAtual, '80kg 3x8');
    expect(supino.cargaSugerida, '82,5kg 3x8 ou 80kg 3x10');
    expect(supino.justificativa, contains('2,5kg'));

    expect(parsed.footer, contains('aquecer'));
  });

  test('toPlainText formats readable copy payload', () {
    final parsed = parseIaProgressaoMarkdown(sampleMarkdown);
    final plain = parsed.toPlainText();

    expect(plain, contains('Supino'));
    expect(plain, contains('Atual: 80kg 3x8'));
    expect(plain, contains('Sugerido: 82,5kg 3x8 ou 80kg 3x10'));
    expect(plain, isNot(contains('|')));
  });

  test('falls back to raw markdown when no table is present', () {
    const raw = 'Resposta sem tabela, apenas texto corrido.';
    final parsed = parseIaProgressaoMarkdown(raw);

    expect(parsed.hasStructuredRows, isFalse);
    expect(parsed.toPlainText(), raw);
  });
}
