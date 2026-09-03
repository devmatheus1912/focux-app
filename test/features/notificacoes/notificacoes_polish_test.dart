import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('notificacoes usa polish: inbox, a11y e feedback', () {
    final screen = readScreenSourceBundle(
      'lib/features/notificacoes/screens/notificacoes_screen.dart',
    );

    expect(screen, contains('FxHubFreshness'));
    expect(screen, contains('formatDisplayName'));
    expect(screen, contains('Todas marcadas como lidas.'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, isNot(contains('FxSettingsGroupedList')));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('roleHomePath'));
    expect(screen, contains('Semantics('));
    expect(screen, contains('Marcar todas as notificações como lidas'));
    expect(screen, contains('radarSignalDedupeKey'));
    expect(screen, isNot(contains('Abrir sinais do Radar Focux')));
    expect(screen, isNot(contains("freshnessLabel ?? 'INBOX'")));
  });
}
