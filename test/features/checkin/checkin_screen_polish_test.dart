import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('checkin cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/checkin/screens/checkin_screen.dart',
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
    expect(screen, contains('fxConfirmLeaveExecution'));
    expect(screen, contains('FxExecutionKeepAwake'));
    expect(screen, contains('FxExecutionPopGuard'));
    expect(screen, contains('_sair'));
    expect(screen, contains('_abrirFila'));
    expect(screen, contains('_currentExercise'));
    expect(screen, contains('useMesh: false'));
    expect(screen, contains('scaffoldBackgroundColor'));
    expect(screen, contains('ColoredBox'));
    expect(screen, contains('checkinSerieRepsSeed'));
    expect(screen, contains('Preparando seu treino'));
    expect(screen, contains('CheckinRestFocusView'));
    expect(screen, contains('checkinExecutionControlMin'));
    expect(screen, contains('checkinFinalizarLabel'));
    expect(screen, contains('Trocar exercício'));
    expect(screen, contains('selectedId:'));
    expect(screen, contains('FxLoading'));
    expect(screen, isNot(contains('ListView(')));
    expect(screen, isNot(contains('SkeletonList')));
    expect(screen, isNot(contains('CheckinRestTimerDock')));
    expect(screen, isNot(contains('CheckinLiveCoachingCard')));
    expect(screen, isNot(contains('CheckinLiveBadge')));
    expect(screen, isNot(contains('Ver fila')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });

  test('fila do checkin é picker inset, sem ListTile', () {
    final sheet = readScreenSourceBundle(
      'lib/features/checkin/widgets/checkin_execucao_sheets.dart',
    );
    expect(sheet, contains('showFxInsetPickerSheet'));
    expect(sheet, contains('FxInsetPickerSheetItem'));
    expect(sheet, contains('selectedId'));
    expect(sheet, isNot(contains('ListTile(')));
  });

  test('checkin header é S8 sem badge ao vivo', () {
    final header = readScreenSourceBundle(
      'lib/features/checkin/widgets/checkin_header_widgets.dart',
    );
    expect(header, contains("child: const Text('Sair')"));
    expect(header, contains('checkinExecutionControlMin'));
    expect(header, contains('FxHelpIconButton'));
    expect(header, isNot(contains('CheckinLiveBadge')));
    expect(header, isNot(contains('AO VIVO')));
    expect(header, isNot(contains('chevron_left')));
    expect(header, isNot(contains('LinearProgressIndicator')));
    expect(header, isNot(contains('CheckinHeaderMetric')));
  });

  test('checkin serie card é um alvo, sem chevron', () {
    final card = readScreenSourceBundle(
      'lib/features/checkin/widgets/checkin_exercise_widgets.dart',
    );
    expect(card, contains('checkinExecutionControlMin'));
    expect(card, contains('FxLiquidPrimaryButton'));
    expect(card, contains('checkinTextLooksNonPtBr'));
    expect(card, contains('checkinErrosComunsFallback'));
    expect(card, contains('CheckinExerciseVideoPreview'));
    expect(card, contains('CheckinExerciseThumbnailPreview'));
    expect(card, contains('CheckinExerciseMediaPreview'));
    expect(card, contains("'Demonstração'"));
    expect(card, isNot(contains("'Ampliar'")));
    expect(card, contains('FxStripCard'));
    expect(card, contains('BrandPalette.accent'));
    expect(card, contains('_CheckinPosturaHelp'));
    expect(card, contains('FxHelpIconButton'));
    expect(card, contains('Ajuda de postura'));
    expect(card, contains('ValueKey'));
    expect(card, isNot(contains('OutlinedButton.icon')));
    expect(card, isNot(contains('ExpansionTile')));
    expect(card, isNot(contains('LinearProgressIndicator')));
    expect(card, isNot(contains('GatedPoseCoachPanel')));
  });

  test('checkin execution alinha card no topo com scroll', () {
    final screen = readScreenSourceBundle(
      'lib/features/checkin/screens/checkin_screen.dart',
    );
    expect(screen, contains('alignment: Alignment.topCenter'));
    expect(screen, contains('onOpenTips:'));
    expect(screen, contains('CheckinSerieCard'));
  });

  test('RPE sheet esconde hint longo após first-use', () {
    final sheet = readScreenSourceBundle(
      'lib/features/checkin/widgets/checkin_serie_detail_widgets.dart',
    );
    expect(sheet, contains('checkinConsumeRpeFirstUseHint'));
    expect(sheet, contains('FxHelpIconButton'));
    expect(sheet, contains('Esforço sentido'));
    expect(sheet, contains('showFxHelpSheet'));
    expect(sheet, contains('FxKeyboardDismissScope'));
    expect(sheet, contains('FxKeyboardDismissScope.dismiss'));
    expect(sheet, contains('ScrollViewKeyboardDismissBehavior.onDrag'));
    expect(sheet, contains('onTapOutside'));
    expect(sheet, contains('FxHomeSheetSurface'));
  });

  test('demo sheet usa preview maior com autoplay muted', () {
    final media = readScreenSourceBundle(
      'lib/features/checkin/widgets/checkin_media_widgets.dart',
    );
    expect(media, contains('checkinMediaPreviewHeight'));
    expect(media, contains('setVolume(0)'));
    expect(media, contains('setLooping(true)'));
    expect(media, contains('didUpdateWidget'));
    expect(media, contains('_load('));
    expect(media, isNot(contains('IconButton.filled')));
    expect(media, isNot(contains('height: 168')));
  });

  test('troca de exercício remonta o card com ValueKey', () {
    final screen = readScreenSourceBundle(
      'lib/features/checkin/screens/checkin_screen.dart',
    );
    expect(screen, contains('ValueKey('));
    expect(screen, contains('treinoExercicioId'));
  });

  test('postura camera abre full-screen, nao sheet aninhado', () {
    final camera = readScreenSourceBundle(
      'lib/features/checkin/widgets/pose_coach_camera_mobile.dart',
    );
    expect(camera, contains('fullscreenDialog: true'));
    expect(camera, contains('rootNavigator: true'));
    expect(camera, contains('_CameraCoachPage'));
    expect(camera, isNot(contains('showFxHomeSheet')));
    final sheet = readScreenSourceBundle(
      'lib/features/checkin/widgets/checkin_execucao_sheets.dart',
    );
    expect(sheet, contains('expand: true'));
    expect(sheet, contains('ListView'));
    expect(sheet, contains('GatedPoseCoachPanel'));
  });

}
