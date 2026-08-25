import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/fx_settings_layout.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';

void main() {
  test('ajustes: estrutura ChatGPT/iOS, escala da Home', () {
    expect(FxSettingsLayout.pageInset, TokensStrip.s4);
    expect(FxSettingsLayout.groupGap, TokensStrip.s5);
    expect(FxSettingsLayout.groupRadius, 20);
    expect(FxSettingsLayout.rowMinHeight, 52);
    expect(FxSettingsLayout.iconSize, 22);
    expect(FxSettingsLayout.avatarSize, TokensStrip.s9);
    expect(
      File('lib/core/theme/fx_settings_layout.dart').readAsStringSync(),
      contains('FocuxHubTypography'),
    );
  });
}
