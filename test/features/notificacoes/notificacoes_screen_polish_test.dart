import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('notificacoes cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/notificacoes/screens/notificacoes_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxSettingsGroupedList'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('notificacoesViewed'));
    expect(screen, contains('Carregar mais'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
  });
}
