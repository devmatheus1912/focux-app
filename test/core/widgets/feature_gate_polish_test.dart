import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FeatureGate loading uses SkeletonList, never spinner-only', () {
    final gate = File('lib/core/widgets/feature_gate.dart').readAsStringSync();
    expect(gate, contains('SkeletonList'));
    expect(gate, isNot(contains('FxLoading')));
    expect(gate, isNot(contains('CircularProgressIndicator')));
    expect(gate, contains('UpgradePromptSheet.showIfAllowed'));
  });
}
