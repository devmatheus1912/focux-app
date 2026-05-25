import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/notificacoes/notificacao_display.dart';

void main() {
  test('formatDisplayName title-cases single and multi-word names', () {
    expect(formatDisplayName('thales'), 'Thales');
    expect(formatDisplayName('  nathalia costa  '), 'Nathalia Costa');
    expect(formatDisplayName('maria da silva'), 'Maria da Silva');
  });
}
