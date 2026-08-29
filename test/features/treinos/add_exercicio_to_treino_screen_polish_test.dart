import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('add exercicio to treino cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/treinos/screens/add_exercicio_to_treino_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, isNot(contains('centerTitle: true')));
    expect(screen, contains('BrandPalette.sectionAction'));
    expect(screen, isNot(contains('dashboardPrioritiesChipBackground')));
    expect(
      screen,
      anyOf(
        contains('FxContentWidthLimiter'),
        isNot(contains('constrainWidth: false')),
      ),
    );
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

  test(
    'add exercicio to treino first paint usa picker/home (não dual GET)',
    () {
      final screen = readScreenSourceBundle(
        'lib/features/treinos/screens/add_exercicio_to_treino_screen.dart',
      );
      expect(screen, contains('treinoPickerHomeProvider'));
      expect(screen, contains('ExerciseVideoSpecTips'));
      expect(screen, contains('_SelectedExerciseInsetGroup'));
      expect(screen, contains('FxSettingsLayout.pageInset'));
      expect(screen, isNot(contains('_CompactSelectedExerciseBar')));
      expect(screen, isNot(contains('ExerciseVideoUploadStrip')));
      expect(screen, contains('ref.watch(treinoPickerHomeProvider'));
      expect(screen, isNot(contains('ref.watch(exerciciosProvider)')));
      expect(screen, isNot(contains('ref.watch(treinoProvider(')));
      expect(screen, contains('_BuscarQuickLinks'));
      expect(screen, contains('FxSettingsLayout.groupPadH'));
      expect(screen, contains('reduceMotionOf'));
      expect(screen, contains('fxMotionDurationMs'));

      final repo =
          File(
            'lib/features/treinos/data/treino_repository.dart',
          ).readAsStringSync();
      expect(repo, contains('TreinoPickerUiHints'));
      expect(repo, contains('/picker/home'));
      expect(repo, contains('getPickerHome'));
    },
  );
}
