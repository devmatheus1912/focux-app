import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('meus vídeos do aluno cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/feedback/screens/aluno_feedback_video_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('isPlanGateError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('ListView.builder'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('showFxFormSheet'));
    expect(screen, contains('FxHomeSheetScaffold'));
    expect(screen, contains('launchSafeHttpUrl'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('feedbackVideoRepositoryProvider'));
    expect(screen, contains('feedbackVideoTamanhoErro'));
    expect(screen, contains('maxDuration: feedbackVideoMaxDuration'));
    expect(screen, isNot(contains('poseCoach')));
    expect(screen, isNot(contains('IA')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('FilledButton')));
    expect(screen, isNot(contains('context.pop()')));
    expect(screen, isNot(contains('SnackBar(')));
  });
}
