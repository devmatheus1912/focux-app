import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/notificacoes/notificacao_display.dart';

void main() {
  test('formatDisplayName title-cases single and multi-word names', () {
    expect(formatDisplayName('thales'), 'Thales');
    expect(formatDisplayName('  nathalia costa  '), 'Nathalia Costa');
    expect(formatDisplayName('maria da silva'), 'Maria da Silva');
  });

  test('radarSignalDedupeKey ignora casing e espacos duplicados', () {
    final a = radarSignalDedupeKey(
      displayName: 'Thales',
      summary: 'Retomar treino com mensagem curta',
      route: '/alunos/1',
    );
    final b = radarSignalDedupeKey(
      displayName: 'thales',
      summary: '  Retomar   treino com mensagem curta ',
      route: '/alunos/1',
    );
    expect(a, b);
  });
}
