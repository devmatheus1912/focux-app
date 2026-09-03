import 'dart:io';

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
    expect(screen, contains('Ações do exercício'));
    expect(screen, contains('Ações do treino'));
    expect(screen, contains('showFxHomeSheet'));
    expect(screen, contains('ProductEvents.treinoDetailViewed'));
    expect(screen, contains('ProductEvents.treinoDetailAddTapped'));
    expect(screen, contains('ProductEvents.treinoDetailMenuOpened'));
    expect(screen, contains('ProductEvents.treinoExerciseMenuOpened'));
    expect(screen, contains('ProductEvents.treinoDetailHelpOpened'));
    expect(screen, contains('ProductEvents.treinoDetailRefreshed'));
    expect(screen, contains('ProductEvents.treinoPrescriptionSaved'));
    expect(screen, contains('treinoPrescriptionRejection'));
    expect(screen, contains('openAdd()'));
    expect(screen, contains('Montar por modelo'));
    expect(screen, contains('openMontarPorModelo'));
    expect(screen, contains('TreinosLayout.touchTarget'));
    expect(screen, contains('TreinoHomeSheetSurface'));
    expect(screen, contains('treino_home_sheet.dart'));
    final editor =
        File(
          'lib/features/treinos/widgets/prescription_editor_sheet.dart',
        ).readAsStringSync();
    expect(
      editor,
      allOf(
        contains('FxSettingsGroup'),
        contains('stickyFooter'),
        contains('contextSubtitle'),
        contains('showFxInsetPickerSheet'),
        contains("header: 'Prescrição'"),
        contains("header: 'Mais detalhes'"),
        isNot(contains('AlunoSegmentedChoice')),
      ),
    );
    expect(screen, isNot(contains('ChoiceChip')));
    expect(screen, isNot(contains('DropdownButtonFormField')));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showTreinoDetailHelpSheet'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('treino_detail_grouping.dart'));
    expect(screen, contains('treinoDetailMetaLine'));
    expect(screen, contains('treinoDetailExerciseLine'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('treino_inset_sheet.dart'));
    expect(screen, contains('TreinoInsetActionSheet'));
    final inset = File(
      'lib/features/treinos/widgets/treino_inset_sheet.dart',
    ).readAsStringSync();
    expect(inset, contains('ElevatedButton'));
    expect(inset, contains('child: Text(confirmLabel)'));
    expect(inset, isNot(contains('label: confirmLabel')));
    expect(screen, isNot(contains('_DetailActionTile')));
    expect(screen, isNot(contains('_TreinoHeroActions')));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxHomeSheetHandle'));
    expect(screen, contains('expand: true'));
    expect(screen, contains('TreinoPrescriptionVideoBlock'));
    expect(screen, contains('treino_prescription_video_block.dart'));
    expect(screen, contains('prescription_editor_sheet.dart'));
    expect(screen, contains('PrescriptionEditorSheet'));
    expect(screen, contains('matchWorkoutBuilderPresetId'));
    expect(screen, isNot(contains('treino_prescription_form.dart')));
    expect(screen, isNot(contains('TreinoPrescriptionField')));
    expect(screen, isNot(contains('TreinoTipoSeriePicker')));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('treinoPrescriptionSaveConfirmTitle'));
    expect(screen, contains('heightFactor: 0.88'));
    final videoBlock =
        File(
          'lib/features/treinos/widgets/treino_prescription_video_block.dart',
        ).readAsStringSync();
    expect(
      videoBlock,
      allOf(
        contains('ExerciseVideoSpecTips.open'),
        contains('FxSettingsGroup'),
        contains("header: 'Vídeo'"),
        contains('onHelpTap'),
        contains('Semantics('),
        contains('liveRegion: locked'),
        contains('Demo da biblioteca ou envie o seu'),
      ),
    );
    expect(videoBlock, contains('showFxConfirmSheet'));
    expect(videoBlock, contains('showFxInsetPickerSheet'));
    expect(videoBlock, contains('FxSettingsTile'));
    expect(videoBlock, contains('exerciseVideoUploadConfirmTitle'));
    expect(videoBlock, contains('exerciseVideoRemoveConfirmTitle'));
    expect(videoBlock, isNot(contains('TextButton')));
    expect(videoBlock, isNot(contains('FxLiquidPrimaryButton')));
    expect(videoBlock, isNot(contains('Celular em pé')));
    expect(videoBlock, isNot(contains('ExerciseVideoUploadStrip')));
    expect(videoBlock, isNot(contains('fxStripCardDecoration')));
    expect(videoBlock, isNot(contains('Ver seu vídeo')));
    expect(videoBlock, isNot(contains('Opcional · vertical')));
    expect(
      File(
        'lib/features/treinos/widgets/treino_detail_help_sheet.dart',
      ).readAsStringSync(),
      contains('showFxHelpSheet'),
    );
    expect(screen, isNot(contains('durationMin')));
    expect(screen, isNot(contains('* 3.5')));
    expect(screen, isNot(contains('_GridTexturePainter')));
    expect(screen, isNot(contains('_HeroMetricChip')));
    expect(screen, isNot(contains('_ExerciseActionTile')));
    expect(screen, isNot(contains('Atribua, duplique ou salve como modelo')));
  });
}
