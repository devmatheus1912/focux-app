import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/fx_settings_layout.dart';

void main() {
  test('ajustes usam a escala iOS/ChatGPT no degrau Large', () {
    expect(FxSettingsLayout.fontRow, 17);
    expect(FxSettingsLayout.fontSection, 13);
    expect(FxSettingsLayout.fontProfileName, 22);
    expect(FxSettingsLayout.fontNavTitle, 17);
    expect(FxSettingsLayout.pageInset, 16);
    expect(FxSettingsLayout.groupRadius, 20);
    expect(FxSettingsLayout.rowMinHeight, 52);
    expect(FxSettingsLayout.iconSize, 22);
    expect(FxSettingsLayout.avatarSize, 80);
  });
}
