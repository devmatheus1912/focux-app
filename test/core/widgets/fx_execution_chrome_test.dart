import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('S8 chrome mantém tela acesa e confirma saída', () {
    final src =
        File('lib/core/widgets/fx_execution_chrome.dart').readAsStringSync();
    expect(src, contains('class FxExecutionKeepAwake'));
    expect(src, contains('WakelockPlus.enable()'));
    expect(src, contains('class FxExecutionPopGuard'));
    expect(src, contains('canPop: false'));
    expect(src, contains('fxConfirmLeaveExecution'));
    expect(src, contains('showFxConfirmSheet'));
  });
}
