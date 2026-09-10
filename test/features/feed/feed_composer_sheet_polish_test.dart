import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('composer do feed cumpre S7 form', () {
    final sheet = readScreenSourceBundle(
      'lib/features/feed/widgets/feed_composer_sheet.dart',
    );
    expect(sheet, contains('FxLiquidPrimaryButton'));
    expect(sheet, contains('feedPublicarTileLabel()'));
    expect(sheet, contains('FxHomeSheetChrome.dismissAndPop'));
    expect(sheet, contains('showFxInsetPickerSheet'));
    expect(sheet, contains('LengthLimitingTextInputFormatter'));
    expect(sheet, contains('FxSettingsGroup'));
    expect(sheet, contains('picker: true'));
    expect(sheet, isNot(contains('ElevatedButton')));
    expect(sheet, isNot(contains('showFxConfirmSheet')));
    expect(sheet, isNot(contains('viewInsets.bottom')));
    expect(sheet, isNot(contains('Navigator.of(context).pop')));
  });
}
