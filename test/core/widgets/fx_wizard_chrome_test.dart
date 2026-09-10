import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('S9 chrome sobe com teclado e guarda o back', () {
    final src = File('lib/core/widgets/fx_wizard_chrome.dart').readAsStringSync();
    expect(src, contains('class FxWizardStickyBar'));
    expect(src, contains('FxFormStickyBar'));
    expect(src, contains('class FxWizardPopGuard'));
    expect(src, contains('FxFormPopGuard'));
    expect(src, contains('class FxWizardStepDots'));
    expect(src, contains('Semantics('));
  });
}
