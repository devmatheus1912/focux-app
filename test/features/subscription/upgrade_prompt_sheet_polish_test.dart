import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('upgrade prompt cumpre S7 notice', () {
    final sheet = readScreenSourceBundle(
      'lib/features/subscription/widgets/upgrade_prompt_sheet.dart',
    );
    expect(sheet, contains('showFxHomeSheet'));
    expect(sheet, contains('FxHomeSheetSurface'));
    expect(sheet, contains('FxLiquidPrimaryButton'));
    expect(sheet, contains('FxHomeSheetChrome.dismissAndPop'));
    expect(sheet, isNot(contains('FilledButton')));
    expect(sheet, isNot(contains('Navigator.pop')));
  });
}
