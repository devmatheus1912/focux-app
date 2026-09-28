import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/widgets/checkin_timer_widgets.dart';
import 'package:focux_app/l10n/app_localizations.dart';

import '../../support/screen_source_bundle.dart';

String _src(String path) => readScreenSourceBundle(path);

int _linhas(String path) => File(path).readAsLinesSync().length;

void main() {
  const screenPath = 'lib/features/checkin/screens/checkin_screen.dart';
  const estadosPath =
      'lib/features/checkin/widgets/checkin_execucao_estados.dart';

  test('checkin cumpre contrato Tier S+', () {
    final screen = _src(screenPath);
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('_loading'));
    expect(screen, contains('CheckinPreparandoView'));
    expect(screen, contains('CheckinIniciarErroView'));
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
    expect(screen, contains('showCheckinSerieDetalhe'));
    expect(screen, contains('CheckinRascunhos'));
    expect(screen, contains('CheckinRestFocusView'));
    expect(screen, contains('_registrarSerieRapida'));
    expect(screen, contains('onAjustar:'));
    expect(screen, contains('onConfirmarRestante:'));
    expect(screen, contains('CheckinFinalizarBar'));
    expect(screen, contains('selectedId:'));
    expect(screen, isNot(contains('ListView(')));
    expect(screen, isNot(contains('SkeletonList')));
    expect(screen, isNot(contains('CheckinRestBanner')));
    expect(screen, isNot(contains('CheckinRestTimerDock')));
    expect(screen, isNot(contains('CheckinLiveCoachingCard')));
    expect(screen, isNot(contains('CheckinLiveBadge')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));

    final estados = _src(estadosPath);
    expect(estados, contains('FxLoading'));
    expect(estados, contains('.checkinPreparando'));
    expect(estados, contains('checkinExecutionControlMin'));
    expect(estados, contains('s.checkinFinalizarTreino'));
    expect(estados, contains('liveRegion: true'));
    expect(estados, isNot(contains('CircularProgressIndicator')));
  });

  test('execução fica abaixo de 500 linhas por arquivo', () {
    for (final path in [
      screenPath,
      'lib/features/checkin/screens/checkin_screen_corpo.part.dart',
      'lib/features/checkin/widgets/checkin_serie_detail_widgets.dart',
      'lib/features/checkin/widgets/checkin_exercise_widgets.dart',
      estadosPath,
    ]) {
      expect(_linhas(path), lessThan(500), reason: path);
    }
  });

  test('fila offline, finalizar e descanso vivem fora do layout', () {
    final screen = _src(screenPath);
    expect(screen, contains('checkinEnviarFila'));
    expect(screen, contains('checkinErroDeConexao'));
    expect(screen, contains('_filaLimpa'));
    expect(screen, contains('checkinExerciciosFaltando'));
    expect(screen, contains('showCheckinFinalizarIncompleto'));
    expect(screen, contains('CheckinDescansoRelogio'));
    expect(screen, contains('checkinConexaoVoltouProvider'));
    expect(screen, contains('checkinDescansoAlertaProvider'));
    expect(screen, contains('AppLifecycleState.resumed'));
    expect(screen, contains('removerDaExecucao'));
    final corpo =
        File(
          'lib/features/checkin/screens/checkin_screen_corpo.part.dart',
        ).readAsStringSync();
    expect(corpo, isNot(contains('setState(')));
    expect(corpo, contains('CheckinPendentesAviso'));
    final sheets = _src(
      'lib/features/checkin/widgets/checkin_execucao_sheets.dart',
    );
    expect(sheets, contains('s.checkinFaltamExercicios'));
    expect(sheets, contains('s.checkinVoltarAoTreino'));
    final relogio = _src(
      'lib/features/checkin/utils/checkin_descanso_relogio.dart',
    );
    expect(relogio, contains('checkinRestRemaining'));
    expect(relogio, contains('sincronizar'));
  });

  test('timer de descanso usa texto do ARB', () {
    final timers = _src(
      'lib/features/checkin/widgets/checkin_timer_widgets.dart',
    );
    expect(
      timers,
      allOf(
        contains('class CheckinRestFocusView'),
        contains('checkinRestRingSize'),
        contains('TokensStrip.fontH1'),
        contains('checkinExecutionControlMin + 8'),
        contains('this.onTrocar'),
        contains('this.contextLine'),
      ),
    );
    expect(timers, contains('checkinRestSemanticsLabel'));
    expect(timers, contains('BrandPalette.accent'));
    expect(timers, contains('ExcludeSemantics'));
    expect(timers, contains('_CheckinRestRingPainter'));
    expect(timers, contains('s.checkinTrocar'));
    expect(timers, contains('s.checkinPularDescanso'));
    expect(timers, isNot(contains('CircularProgressIndicator')));
    expect(timers, isNot(contains('class CheckinRestBanner')));
    expect(timers, isNot(contains('FxLoading')));
    expect(timers, isNot(contains('FxLiquidPrimaryButton')));
    expect(timers, contains('TextButton('));
    expect(timers, isNot(contains('FilledButton')));
  });

  test('fila do checkin é picker inset, sem ListTile', () {
    final sheet = _src(
      'lib/features/checkin/widgets/checkin_execucao_sheets.dart',
    );
    expect(sheet, contains('showFxInsetPickerSheet'));
    expect(sheet, contains('FxInsetPickerSheetItem'));
    expect(sheet, contains('selectedId'));
    expect(sheet, isNot(contains('ListTile(')));
  });

  test('checkin header é S8 sem badge ao vivo', () {
    final header = _src(
      'lib/features/checkin/widgets/checkin_header_widgets.dart',
    );
    expect(header, contains('s.checkinSair'));
    expect(header, contains('checkinExecutionControlMin'));
    expect(header, contains('FxHelpIconButton'));
    expect(header, isNot(contains('CheckinLiveBadge')));
    expect(header, isNot(contains('AO VIVO')));
    expect(header, isNot(contains('chevron_left')));
    expect(header, isNot(contains('LinearProgressIndicator')));
    expect(header, isNot(contains('CheckinHeaderMetric')));
  });

  test('checkin serie card é um alvo, sem chevron nem Demonstração', () {
    final card = _src(
      'lib/features/checkin/widgets/checkin_exercise_widgets.dart',
    );
    expect(card, contains('checkinExecutionControlMin'));
    expect(card, contains('this.resting'));
    expect(card, contains('if (!resting)'));
    expect(card, contains('FxLiquidPrimaryButton'));
    expect(card, contains('s.checkinAjustar'));
    expect(card, contains('s.checkinMais'));
    expect(card, contains('s.checkinMaisTitulo'));
    expect(card, contains('showFxHomeSheet'));
    expect(card, contains('checkinConfirmarRestanteLabel'));
    expect(card, contains('checkinTrocarExercicioHint'));
    expect(card, contains('_CheckinSetSteppers'));
    expect(card, contains('_CheckinStepperButton'));
    expect(card, contains('s.checkinDiminuir'));
    expect(card, contains('CheckinExerciseVideoPreview'));
    expect(card, contains('CheckinExerciseThumbnailPreview'));
    expect(card, contains('CheckinExerciseMediaPreview'));
    expect(card, isNot(contains('Demonstração')));
    expect(card, isNot(contains('onOpenDemo')));
    expect(card, isNot(contains("'Postura'")));
    expect(card, isNot(contains('onOpenCoach')));
    expect(card, isNot(contains("'Dicas'")));
    expect(card, isNot(contains('onOpenTips')));
    expect(card, isNot(contains("'Ampliar'")));
    expect(card, contains('FxStripCard'));
    expect(card, contains('glowStrength: resting ? 0 : 0.04'));
    expect(card, contains('glowStrength: 0'));
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
    final tips = _src('lib/features/checkin/utils/checkin_exercise_tips.dart');
    expect(tips, contains('checkinTextLooksNonPtBr'));
    expect(tips, contains('checkinErrosComunsFallback'));
    expect(tips, contains('showCheckinExerciseTipsSheet'));
    expect(tips, contains('checkinExerciseHasDemo'));
  });

  test('checkin execution alinha card no topo com scroll', () {
    final screen = _src(screenPath);
    expect(screen, contains('alignment: Alignment.topCenter'));
    expect(screen, contains('onHelp:'));
    expect(screen, contains('showCheckinExerciseTipsSheet'));
    expect(screen, isNot(contains('onOpenTips:')));
    expect(screen, contains('CheckinSerieCard'));
    expect(screen, contains('resting: _descanso.ativo'));
  });

  test('descanso substitui o card e deixa Trocar em texto', () {
    final screen = _src(screenPath);
    expect(screen, isNot(contains('Positioned(')));
    expect(screen, contains('_descanso.ativo'));
    expect(screen, contains('CheckinRestFocusView('));
    expect(screen, contains('totalSeconds: _descanso.total'));
    expect(screen, contains('checkinRestContextLine'));
    expect(screen, contains('fxAnnounce'));
    expect(screen, contains('!_descanso.ativo'));
  });

  testWidgets('Pular e Trocar ficam tocáveis no lockup de descanso', (
    tester,
  ) async {
    var trocarTaps = 0;
    var skipTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: CheckinRestFocusView(
            seconds: 69,
            totalSeconds: 75,
            contextLine: 'Série 2 de 4 · Supino reto',
            onSkip: () => skipTaps++,
            onTrocar: () => trocarTaps++,
          ),
        ),
      ),
    );

    expect(find.text('1:09'), findsOneWidget);
    expect(find.text('Série 2 de 4 · Supino reto'), findsOneWidget);
    await tester.tap(find.text('Trocar'));
    await tester.tap(find.text('Pular descanso'));
    expect(trocarTaps, 1);
    expect(skipTaps, 1);
    expect(find.byType(TextButton), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  test('RPE sheet esconde hint longo após first-use', () {
    final sheet =
        '${_src('lib/features/checkin/widgets/checkin_serie_detail_widgets.dart')}\n'
        '${_src('lib/features/checkin/widgets/checkin_serie_campos_widgets.dart')}';
    expect(sheet, contains('checkinConsumeRpeFirstUseHint'));
    expect(sheet, contains('FxHelpIconButton'));
    expect(sheet, contains('Esforço sentido'));
    expect(sheet, contains('showFxHelpSheet'));
    expect(sheet, contains('FxKeyboardDismissScope'));
    expect(sheet, contains('FxKeyboardDismissScope.dismiss'));
    expect(sheet, contains('ScrollViewKeyboardDismissBehavior.onDrag'));
    expect(sheet, contains('onTapOutside'));
    expect(sheet, contains('FxHomeSheetSurface'));
    expect(sheet, contains('checkinFeedbackChipMin'));
    expect(sheet, isNot(contains('class CheckinTinyMetric')));
  });

  test('demo sheet usa preview maior com autoplay muted', () {
    final media = _src(
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
    final screen = _src(screenPath);
    expect(screen, contains('ValueKey('));
    expect(screen, contains('treinoExercicioId'));
  });

  test('execução não embute Pose Coach nem sheet de demonstração', () {
    final sheet = _src(
      'lib/features/checkin/widgets/checkin_execucao_sheets.dart',
    );
    expect(sheet, isNot(contains('showCheckinCoachSheet')));
    expect(sheet, isNot(contains('GatedPoseCoachPanel')));
    expect(sheet, isNot(contains('showCheckinDemoSheet')));
    expect(
      File(
        'lib/features/checkin/widgets/gated_pose_coach_panel.dart',
      ).existsSync(),
      isFalse,
    );
    expect(
      File('lib/features/checkin/widgets/pose_coach_panel.dart').existsSync(),
      isFalse,
    );
  });
}
