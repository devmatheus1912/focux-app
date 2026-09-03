import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('ia aluno cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/ia/screens/ia_aluno_screen.dart');
    final composer =
        File('lib/features/ia/widgets/ia_chat_composer.dart').readAsStringSync();
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('IaChatComposer'));
    expect(composer, contains('onTapOutside'));
    expect(composer, isNot(contains('IconButton.filled')));
    expect(screen, isNot(contains('IconButton.filled')));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('IndexedStack'));
    expect(screen, contains('IaSafetyDisclaimer'));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('TabBarView')));
    expect(screen, isNot(contains('TabController')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
