import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('treino detail cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/treinos/screens/treino_detail_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(
      screen,
      anyOf(
        contains('friendlyError'),
        contains('DashboardErrorState'),
        contains('FxEmptyState'),
        contains('_erro'),
        contains('_TrainingEmptyState'),
        contains('ref.invalidate'),
      ),
    );
    expect(
      screen,
      anyOf(
        contains('FxLoading'),
        contains('SkeletonLoader'),
        contains('SkeletonList'),
        contains('DashboardShimmer'),
        contains('Shimmer'),
        contains('IaCopilotInsightsLoading'),
        contains('_loading'),
      ),
    );
  });

  test('treino detail segue o ritmo visual da Home', () {
    final screen = readScreenSourceBundle(
      'lib/features/treinos/screens/treino_detail_screen.dart',
    );

    expect(screen, contains('FocuxHubTypography'));
    expect(screen, contains('Escolha uma ação.'));
    expect(screen, contains('useRootNavigator: true'));
    expect(screen, contains('ProductEvents.treinoDetailViewed'));
    expect(screen, contains('ProductEvents.treinoDetailAddTapped'));
    expect(screen, contains('ProductEvents.treinoDetailMenuOpened'));
    expect(screen, contains('ProductEvents.treinoExerciseMenuOpened'));
    expect(screen, contains('ProductEvents.treinoDetailHelpOpened'));
    expect(screen, contains('ProductEvents.treinoDetailRefreshed'));
    expect(screen, contains("source: 'empty'"));
    expect(screen, contains('TreinosLayout.touchTarget'));
    expect(screen, contains('chrome.bottomSheet'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('showTreinoDetailHelpSheet'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('treino_detail_grouping.dart'));
    expect(screen, contains('treinoDetailMetaLine'));
    expect(screen, contains('FxInputDeco.build'));
    expect(screen, contains('ChoiceChip'));
    expect(screen, contains('_TreinoSheetChromeHeader'));
    expect(screen, isNot(contains('DropdownButtonFormField')));
    expect(screen, isNot(contains('durationMin')));
    expect(screen, isNot(contains('* 3.5')));
    expect(screen, isNot(contains('_GridTexturePainter')));
    expect(screen, isNot(contains('_HeroMetricChip')));
    expect(screen, isNot(contains('_ExerciseActionTile')));
    expect(screen, isNot(contains('Atribua, duplique ou salve como modelo')));
  });
}
