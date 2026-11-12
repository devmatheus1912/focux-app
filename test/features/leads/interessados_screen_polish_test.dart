import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

/// Interessados (11/11): uma lista em etapas, sem kanban nem filtros.
void main() {
  test('interessados cumpre contrato e o redesign', () {
    final screen = readScreenSourceBundle(
      'lib/features/leads/screens/interessados_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('FeatureGate'));
    expect(screen, contains('interessadosAgrupar'));
    expect(screen, contains("'Novo interessado'"));
    expect(screen, contains("'Copiar link da página'"));
    expect(screen, contains('contatarInteressado'));
    expect(screen, contains('interessadosMostraBusca'));
    expect(screen, isNot(contains('Kanban')));
    expect(screen, isNot(contains("'Funil de Leads'")));
    expect(screen, isNot(contains('FxToggleChip')));
  });
}
