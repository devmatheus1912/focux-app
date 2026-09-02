import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('pacotes cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/pacotes/screens/pacotes_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('ShellHeaderIconButton'));
    expect(screen, isNot(contains('FloatingActionButton')));
  });

  test('novo plano usa form inset', () {
    final sheet = readScreenSourceBundle(
      'lib/features/pacotes/widgets/pacotes_storefront_widgets.dart',
    );
    expect(sheet, contains('AlunoInsetFormField'));
    expect(sheet, contains('showFxInsetPickerSheet'));
    expect(sheet, contains('FxSettingsGroup'));
    expect(sheet, contains('showFxConfirmSheet'));
    expect(sheet, contains('pacoteCriarConfirmTitle'));
    expect(sheet, isNot(contains('FxLiquidPrimaryButton')));
    expect(sheet, isNot(contains('FxLiquidSecondaryButton')));
    expect(sheet, isNot(contains('ChoiceChip')));
    expect(sheet, isNot(contains('DropdownButton')));
  });
}
