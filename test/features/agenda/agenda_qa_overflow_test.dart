import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/qa/widgets/qa_route_preview.dart';

void main() {
  testWidgets('agenda preview has no flex overflow at 430px', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(child: buildQaRoutePreviewApp('/agenda')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final exception = tester.takeException();
    expect(
      exception,
      isNull,
      reason: exception?.toString(),
    );
  });
}
