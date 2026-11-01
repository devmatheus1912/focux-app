import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('meu progresso cumpre contrato Tier S+', () {
    final screen = File(
      'lib/features/dashboard/screens/meu_progresso_screen.dart',
    ).readAsStringSync();
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('EvolucaoMedidasAba'));
    expect(screen, contains('EvolucaoRecordesAba'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
  });
}
