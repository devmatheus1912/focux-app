import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('upgrade prompt cumpre S7 notice', () {
    final sheet = readScreenSourceBundle(
      'lib/features/subscription/widgets/upgrade_prompt_sheet.dart',
    );
    final sales = readScreenSourceBundle(
      'lib/features/subscription/widgets/fx_upgrade_sales_sheet.dart',
    );
    final bundle = '$sheet\n$sales';
    expect(bundle, contains('showFxHomeSheet'));
    expect(bundle, contains('FxHomeSheetScaffold'));
    expect(bundle, contains('FxLiquidPrimaryButton'));
    expect(bundle, contains('FxHomeSheetChrome.dismissAndPop'));
    expect(sheet, isNot(contains('FilledButton')));
    expect(sheet, isNot(contains('Navigator.pop')));
  });
}
