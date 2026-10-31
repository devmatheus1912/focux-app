import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('notificacoes usa polish: inbox, a11y e feedback', () {
    final screen = readScreenSourceBundle(
      'lib/features/notificacoes/screens/notificacoes_screen.dart',
    );

    expect(screen, contains('FxHubFreshness'));
    expect(screen, contains('notificacaoNomeLimpo'));
    expect(screen, contains('notificacoesTodasMarcadasComoLidas'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, isNot(contains('FxSettingsGroupedList')));
    expect(screen, contains('showFxHelpSheet'));
    expect(screen, contains('roleHomePath'));
    expect(screen, contains('Semantics('));
    expect(screen, contains('notificacoesMarcarTodasAsNotificacoesComo'));
    expect(screen, contains('radarSignalDedupeKey'));
    expect(screen, isNot(contains('Abrir sinais do Radar Focux')));
    expect(screen, isNot(contains("freshnessLabel ?? 'INBOX'")));
  });

  test('lidas: destaque real, contagem de não lidas e sino da Home', () {
    final screen = readScreenSourceBundle(
      'lib/features/notificacoes/screens/notificacoes_screen.dart',
    );
    expect(screen, contains('unread ? FontWeight.w700 : FontWeight.w500'));
    expect(screen, contains("ValueKey('notificacao-nao-lida')"));
    expect(screen, contains('notificacaoNaoLidasLabel(unreadCount)'));
    expect(screen, isNot(contains('inbox.total),')));
    expect(screen, contains('invalidateAlunoDashboardHome(ref)'));
    expect(screen, contains('invalidatePersonalDashboardHome(ref)'));
    expect(screen, contains('item.ctaLabel'));
  });
}
