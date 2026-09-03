import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('composer do feed é S5 com CTA líquido', () {
    final sheet = readScreenSourceBundle(
      'lib/features/feed/widgets/feed_composer_sheet.dart',
    );
    expect(sheet, contains('FxLiquidPrimaryButton'));
    expect(sheet, contains('feedPublicarTileLabel()'));
    expect(sheet, isNot(contains('ElevatedButton')));
    expect(sheet, contains('showFxInsetPickerSheet'));
    expect(sheet, contains('feedPublicarConfirmTitle'));
    expect(sheet, contains('LengthLimitingTextInputFormatter'));
    expect(sheet, contains('FxSettingsGroup'));
    expect(sheet, contains('picker: true'));
    expect(sheet, contains('label: feedPublicarTileLabel()'));
  });
}
