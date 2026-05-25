import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('planos usa polish 10/10: assinatura, a11y e erro de trial', () {
    final screen = File(
      'lib/features/planos/screens/planos_screen.dart',
    ).readAsStringSync();

    expect(screen, contains("subtitle: 'ASSINATURA'"));
    expect(screen, contains('FeedbackHelper.showError'));
    expect(screen, isNot(contains('showSuccess(context, \'Erro')));
    expect(screen, contains('Semantics('));
    expect(screen, contains('Não inclui'));
    expect(screen, contains('loadingLabel: \'Ativando…\''));
    expect(screen, isNot(contains('google_fonts')));
  });
}
