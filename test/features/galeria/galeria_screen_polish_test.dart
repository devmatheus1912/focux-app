import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('galeria cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/galeria/screens/galeria_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('MediaUploadService'));
    expect(screen, contains("folder: 'galeria'"));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('galeriaCountLabel'));
    expect(screen, isNot(contains('Icons.add_photo_alternate_outlined')));
    expect(screen, isNot(contains('focux_unsigned')));
    expect(screen, isNot(contains('api.cloudinary.com')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
    expect(screen, contains('PopScope'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('listarPagina'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
  });
}
