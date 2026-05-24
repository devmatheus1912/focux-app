import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/qa/data/qa_smoke_catalog.dart';
import 'package:focux_app/features/qa/widgets/qa_route_preview.dart';

void main() {
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
