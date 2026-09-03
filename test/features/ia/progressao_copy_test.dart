import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/utils/progressao_copy.dart';

void main() {
  test('progressaoPendingReviewLabel pluraliza corretamente', () {
    expect(progressaoPendingReviewLabel(0), 'Revisar sugestões pendentes');
    expect(progressaoPendingReviewLabel(1), 'Revisar 1 sugestão pendente');
    expect(progressaoPendingReviewLabel(3), 'Revisar 3 sugestões pendentes');
  });

  test('chrome e limites do pedido de progressão', () {
    expect(progressaoObjetivoMax, 500);
    expect(progressaoHistoricoMax, 8000);
    expect(progressaoHubSubtitle(''), 'Sugestão de carga, só se você pedir');
    expect(progressaoHubSubtitle('  Ana  '), 'Ana · só se você pedir');
    expect(progressaoStickyLabel(hasResult: false), 'Gerar progressão');
    expect(progressaoStickyLabel(hasResult: true), 'Gerar outra');
    expect(progressaoStickyLoadingLabel(), 'Gerando…');
    expect(progressaoConfirmTitle(), 'Gerar progressão com IA?');
    expect(progressaoConfirmLabel(), 'Gerar');
  });
}
