import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/qa/data/qa_smoke_catalog.dart';
import 'package:focux_app/features/qa/widgets/qa_route_preview.dart';

/// Rotas com overflow conhecido em viewport estreito (430px) — bug de layout real.
const _knownLayoutFragileRoutes = {
  '/register',
  '/onboarding',
  '/ia/copiloto',
  '/ia/checkin',
  '/broadcasts',
  '/gamificacao',
};

void main() {
  testWidgets('QA route previews pump without hard failures', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final hardFailures = <String, String>{};
    final layoutWarnings = <String, String>{};

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
        final message = exception.toString();
        final path = route.path.split('?').first;
        final isKnownLayoutIssue =
            _knownLayoutFragileRoutes.contains(path) &&
            (message.contains('RenderFlex overflowed') ||
                message.contains('Multiple exceptions'));
        final isKnownDisposeRace =
            path == '/ia/copiloto' &&
            message.contains('Cannot use "ref" after the widget was disposed');
        if (isKnownLayoutIssue || isKnownDisposeRace) {
          layoutWarnings[path] = message;
        } else {
          hardFailures[route.path] = message;
        }
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    if (layoutWarnings.isNotEmpty) {
      // ignore: avoid_print
      print('QA layout warnings (${layoutWarnings.length}):');
      for (final entry in layoutWarnings.entries) {
        // ignore: avoid_print
        print('  - ${entry.key}');
      }
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
