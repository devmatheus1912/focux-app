import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('presencial é S8 com pai, wake e confirm', () {
    final screen = readScreenSourceBundle(
      'lib/features/checkin/screens/modo_presencial_screen.dart',
    );
    expect(screen, contains('FxExecutionKeepAwake'));
    expect(screen, contains('FxExecutionPopGuard'));
    expect(screen, contains('fxConfirmLeaveExecution'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('/treinos/'));
    expect(screen, contains('useMesh: false'));
    expect(screen, contains('checkinExecutionControlMin'));
    expect(screen, contains('CheckinRestFocusView'));
    expect(screen, contains('didChangeAppLifecycleState'));
    expect(screen, isNot(contains('Navigator.pop')));
    expect(screen, isNot(contains('ListView(')));
    expect(screen, isNot(contains('FxSettingsGroup')));
  });
}
