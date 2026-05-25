import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notificacoes usa polish 10/10: inbox, a11y e feedback', () {
    final screen = File(
      'lib/features/notificacoes/screens/notificacoes_screen.dart',
    ).readAsStringSync();

    expect(screen, contains("subtitle: 'INBOX'"));
    expect(screen, contains('formatDisplayName'));
    expect(screen, contains('Todas marcadas como lidas.'));
    expect(screen, contains('BrandPalette.deep(primary)'));
    expect(screen, contains('Semantics('));
    expect(screen, contains('Marcar todas as notificações como lidas'));
    expect(screen, contains('Abrir sinais do Radar Focux'));
  });
}
