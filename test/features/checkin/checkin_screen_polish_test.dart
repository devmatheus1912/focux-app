import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/widgets/checkin_timer_widgets.dart';

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
    expect(screen, contains('showFxExecutionLeaveSheet'));
    expect(screen, contains('FxExecutionKeepAwake'));
    expect(screen, contains('FxExecutionPopGuard'));
    expect(screen, contains('_sair'));
    expect(screen, contains('_abrirFila'));
    expect(screen, contains('onTrocar:'));
    expect(screen, contains('_currentExercise'));
    expect(screen, contains('useMesh: false'));
    expect(screen, contains('scaffoldBackgroundColor'));
    expect(screen, contains('ColoredBox'));
    expect(screen, contains('checkinSerieRepsSeed'));
    expect(screen, contains('Preparando seu treino'));
    expect(screen, contains('CheckinRestBanner'));
    expect(screen, isNot(contains('CheckinRestFocusView')));
    expect(
      readScreenSourceBundle(
        'lib/features/checkin/widgets/checkin_timer_widgets.dart',
      ),
      allOf(contains('class CheckinRestBanner'), isNot(contains('SafeArea('))),
    );
    expect(screen, contains('_registrarSerieRapida'));
    expect(screen, contains('onAjustar:'));
    expect(screen, contains('onConfirmarRestante:'));
    expect(screen, contains('checkinExecutionControlMin'));
    expect(screen, contains('checkinFinalizarLabel'));
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
    expect(card, contains("'Ajustar'"));
    expect(card, contains("'Mais'"));
    expect(card, contains("'Mais na série'"));
    expect(card, contains('showFxHomeSheet'));
    expect(card, contains('checkinConfirmarRestanteLabel'));
    expect(card, contains('checkinTrocarExercicioHint'));
    expect(card, contains('_CheckinSetSteppers'));
    expect(card, contains('_CheckinStepperButton'));
    expect(card, contains('CheckinExerciseVideoPreview'));
    expect(card, contains('CheckinExerciseThumbnailPreview'));
    expect(card, contains('CheckinExerciseMediaPreview'));
    expect(card, contains("'Demonstração'"));
    expect(card, isNot(contains("'Postura'")));
    expect(card, isNot(contains('onOpenCoach')));
    expect(card, isNot(contains("'Dicas'")));
    expect(card, isNot(contains('onOpenTips')));
    expect(card, isNot(contains("'Ampliar'")));
    expect(card, contains('FxStripCard'));
    expect(card, contains('glowStrength: 0.08'));
    expect(card, contains('glowStrength: 0.06'));
    expect(card, contains('BrandPalette.accent'));
    expect(card, isNot(contains('_CheckinPosturaHelp')));
    expect(card, contains('ValueKey'));
    expect(card, contains('VerticalDivider'));
    expect(card, contains('checkin_exercise_tips.dart'));
    expect(card, isNot(contains('OutlinedButton.icon')));
    expect(card, isNot(contains('ExpansionTile')));
    expect(card, isNot(contains('LinearProgressIndicator')));
    expect(card, isNot(contains('GatedPoseCoachPanel')));
    expect(card, isNot(contains('chevron_')));
  });

  test('tips e locale do exercício vivem no util SRP', () {
    final tips = readScreenSourceBundle(
      'lib/features/checkin/utils/checkin_exercise_tips.dart',
    );
    expect(tips, contains('checkinTextLooksNonPtBr'));
    expect(tips, contains('checkinErrosComunsFallback'));
    expect(tips, contains('showCheckinExerciseTipsSheet'));
    expect(tips, contains('checkinExerciseHasDemo'));
  });

  test('checkin execution alinha card no topo com scroll', () {
    final screen = readScreenSourceBundle(
      'lib/features/checkin/screens/checkin_screen.dart',
    );
    expect(screen, contains('alignment: Alignment.topCenter'));
    expect(screen, contains('onHelp:'));
    expect(screen, contains('showCheckinExerciseTipsSheet'));
    expect(screen, isNot(contains('onOpenTips:')));
    expect(screen, contains('CheckinSerieCard'));
  });

  test('faixa de descanso não cobre o toque para trocar', () {
    final screen = readScreenSourceBundle(
      'lib/features/checkin/screens/checkin_screen.dart',
    );
    expect(screen, isNot(contains('Positioned(')));
    expect(screen, isNot(contains('Stack(')));
    expect(screen, contains('if (_showRestTimer)'));
    expect(
      screen.indexOf('CheckinRestBanner('),
      lessThan(screen.indexOf('CheckinSerieCard(')),
    );
    final timers = readScreenSourceBundle(
      'lib/features/checkin/widgets/checkin_timer_widgets.dart',
    );
    expect(timers, contains('this.onTrocar'));
    expect(timers, contains("child: const Text('Trocar')"));
  });

  testWidgets('Trocar e o título ficam tocáveis durante o descanso', (
    tester,
  ) async {
    var trocarTaps = 0;
    var titleTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CheckinRestBanner(
                seconds: 45,
                onSkip: () {},
                onTrocar: () => trocarTaps++,
              ),
              GestureDetector(
                onTap: () => titleTaps++,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: Center(child: Text('Supino reto')),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Trocar'));
    await tester.tap(find.text('Supino reto'));
    expect(trocarTaps, 1);
    expect(titleTaps, 1);
    expect(tester.takeException(), isNull);
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
    expect(media, contains('_release('));
    expect(media, contains('_loadGeneration++'));
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

  test('execução não embute Pose Coach gated no mid-workout', () {
    final sheet = readScreenSourceBundle(
      'lib/features/checkin/widgets/checkin_execucao_sheets.dart',
    );
    expect(sheet, isNot(contains('showCheckinCoachSheet')));
    expect(sheet, isNot(contains('GatedPoseCoachPanel')));
    expect(sheet, contains('showCheckinDemoSheet'));
    expect(
      File('lib/features/checkin/widgets/gated_pose_coach_panel.dart').existsSync(),
      isFalse,
    );
    expect(
      File('lib/features/checkin/widgets/pose_coach_panel.dart').existsSync(),
      isFalse,
    );
  });
}
