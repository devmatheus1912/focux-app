import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/utils/progressao_copy.dart';

void main() {
  test('progressaoPendingReviewLabel pluraliza corretamente', () {
    expect(progressaoPendingReviewLabel(0), 'Revisar sugestões pendentes');
    expect(progressaoPendingReviewLabel(1), 'Revisar 1 sugestão pendente');
    expect(progressaoPendingReviewLabel(3), 'Revisar 3 sugestões pendentes');
  });
}
