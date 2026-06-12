import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/motion_preferences.dart';

void main() {
  testWidgets('reduceMotionOf respects MediaQuery.disableAnimations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: SizedBox(),
      ),
    );
    final context = tester.element(find.byType(SizedBox));
    expect(reduceMotionOf(context), isTrue);
    expect(fxMotionDuration(context).inMilliseconds, 0);
    expect(fxMotionDurationMs(context), 0);
  });

  testWidgets('fxMotionDuration uses normal duration when motion enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: false),
        child: SizedBox(),
      ),
    );
    final context = tester.element(find.byType(SizedBox));
    expect(reduceMotionOf(context), isFalse);
    expect(fxMotionDuration(context).inMilliseconds, 220);
    expect(fxMotionDurationMs(context), 220);
  });

  testWidgets('clampedTextScaler limits system font scale', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: SizedBox(),
      ),
    );
    final context = tester.element(find.byType(SizedBox));
    expect(clampedTextScaler(context, maxScale: 1.2).scale(1), 1.2);
  });
}
