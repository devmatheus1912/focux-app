import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('white label usa polish: denser S2, teclado e sticky save', () {
    final screen = File(
      'lib/features/perfil/screens/white_label_settings_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxSettingsTile'));
    expect(screen, contains('AlunoSegmentedChoice'));
    expect(screen, contains('FxKeyboardDismissScope'));
    expect(screen, contains('FeedbackHelper.showSuccess'));
    expect(screen, contains('FeedbackHelper.showError'));
    expect(screen, contains('Semantics('));
    expect(screen, contains('FxFormStickyBar'));
    expect(screen, contains('FxFormPopGuard'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('ScrollViewKeyboardDismissBehavior.onDrag'));
    expect(screen, contains('whiteLabelCanVerifyDomain'));
    expect(screen, contains('whiteLabelCnameHint'));
    expect(screen, contains('textInputAction'));
    expect(screen, contains('onTapOutside'));
    expect(screen, isNot(contains('SnackBar(content: Text(')));
    expect(screen, isNot(contains('context.pop()')));
    expect(screen, isNot(contains('SwitchListTile')));
    expect(screen, isNot(contains('SegmentedButton')));
    expect(screen, isNot(contains('OperationalMetricTile')));
    expect(screen, isNot(contains('CheckboxListTile')));
  });
}
