import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/gamificacao/utils/gamificacao_display.dart';

void main() {
  test('streak e preview', () {
    expect(gamificacaoStreakLabel(0), '0 dias');
    expect(gamificacaoStreakLabel(1), '1 dia');
    expect(gamificacaoStreakLabel(8), '8 dias');
    expect(gamificacaoBadgePreview([1, 2, 3, 4]), [1, 2, 3]);
    expect(gamificacaoComoCalculamos, contains('Sequência'));
  });
}
