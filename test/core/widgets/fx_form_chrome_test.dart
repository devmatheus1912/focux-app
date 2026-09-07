import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('S5 chrome sobe com teclado e guarda descarte', () {
    final src = File('lib/core/widgets/fx_form_chrome.dart').readAsStringSync();
    expect(src, contains('class FxFormStickyBar'));
    expect(src, contains('viewInsetsOf(context).bottom'));
    expect(src, contains('class FxFormPopGuard'));
    expect(src, contains('canPop: !keyboardOpen && !dirty'));
    expect(src, contains('FxKeyboardDismissScope.dismiss()'));
  });
}
