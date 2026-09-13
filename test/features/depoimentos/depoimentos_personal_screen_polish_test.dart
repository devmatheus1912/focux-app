import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('depoimentos personal cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/depoimentos/screens/depoimentos_personal_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('/perfil/ferramentas'));
    expect(screen, contains('listarParaPersonalPagina'));
    expect(screen, contains('Carregar mais'));
    expect(screen, contains('depoimentoNotaLabel'));
    expect(screen, contains('FxStaggerItem'));
    expect(screen, isNot(contains('FilledButton')));
    expect(screen, isNot(contains('Color(')));
  });
}
