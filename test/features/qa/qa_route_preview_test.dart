import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/qa/data/qa_smoke_catalog.dart';
import 'package:focux_app/features/qa/widgets/qa_route_preview.dart';

void main() {
  test('QA overlay usa chrome S7', () {
    final source = File(
      'lib/features/qa/widgets/qa_route_preview.dart',
    ).readAsStringSync();
    expect(source, contains('showFxHomeSheet'));
    expect(source, contains('FxHomeSheetHeader'));
    expect(source, isNot(contains('showDialog')));
    expect(source, isNot(contains('Dialog.fullscreen')));
  });

  test('QA route preview maps every catalog route', () {
    for (final route in qaSmokeRoutes) {
      expect(
        () => buildQaRoutePreview(route.path),
        returnsNormally,
        reason: route.id,
      );
    }
  });
}
