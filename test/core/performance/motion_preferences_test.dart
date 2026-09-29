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

  Future<TextScaler> clampedDe(WidgetTester tester, TextScaler sistema) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: sistema),
        child: const SizedBox(),
      ),
    );
    return clampedTextScaler(tester.element(find.byType(SizedBox)));
  }

  testWidgets('clampedTextScaler usa o mesmo piso global', (tester) async {
    final escala = await clampedDe(tester, const TextScaler.linear(0.5));
    expect(escala.scale(10), 10 * kAppMinTextScale);
  });

  testWidgets('clampedTextScaler preserva escala não linear do sistema', (
    tester,
  ) async {
    final escala = await clampedDe(tester, const _EscalaNaoLinear());
    expect(escala.scale(10), 11.5);
    expect(escala.scale(40), 42);
  });

  group('appTextScaler', () {
    test('respeita a fonte do sistema até 1,3', () {
      expect(appTextScaler(const TextScaler.linear(1.15)).scale(1), 1.15);
      expect(
        appTextScaler(const TextScaler.linear(1.3)).scale(1),
        kAppMaxTextScale,
      );
    });

    test('corta escalas acima do teto e abaixo do piso', () {
      expect(appTextScaler(const TextScaler.linear(2)).scale(1), 1.3);
      expect(appTextScaler(const TextScaler.linear(0.5)).scale(1), 0.85);
    });
  });
}

/// Como o Android 14: fonte pequena cresce mais que fonte grande.
class _EscalaNaoLinear extends TextScaler {
  const _EscalaNaoLinear();

  @override
  double scale(double fontSize) =>
      fontSize < 20 ? fontSize * 1.15 : fontSize * 1.05;

  @override
  double get textScaleFactor => 1.15;
}
