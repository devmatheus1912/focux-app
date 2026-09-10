import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('NPS prompt cumpre S7 form', () {
    final sheet = readScreenSourceBundle(
      'lib/features/nps/widgets/nps_prompt_dialog.dart',
    );
    expect(sheet, contains('showFxHomeSheet'));
    expect(sheet, contains('FxHomeSheetSurface'));
    expect(sheet, contains('FxLiquidPrimaryButton'));
    expect(sheet, contains('FxHomeSheetChrome.dismissAndPop'));
    expect(sheet, contains('FocuxHubTypography'));
    expect(sheet, isNot(contains('FilledButton')));
    expect(sheet, isNot(contains('FxLoading')));
    expect(sheet, isNot(contains('Navigator.pop')));
  });
}
