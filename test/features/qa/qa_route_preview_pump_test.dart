import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/qa/data/qa_smoke_catalog.dart';
import 'package:focux_app/features/qa/widgets/qa_route_preview.dart';

void main() {
  testWidgets('QA route previews pump without hard failures', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final hardFailures = <String, String>{};

    for (final route in qaSmokeRoutes) {
      await tester.pumpWidget(
        ProviderScope(
          child: buildQaRoutePreviewApp(route.path),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final exception = tester.takeException();
      if (exception != null) {
        hardFailures[route.path] = exception.toString();
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    if (hardFailures.isNotEmpty) {
      final buffer = StringBuffer('Route preview hard failures:\n');
      for (final entry in hardFailures.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value}');
      }
      fail(buffer.toString());
    }
  });
}
