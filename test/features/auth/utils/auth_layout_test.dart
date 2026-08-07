import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/utils/auth_layout.dart';

void main() {
  testWidgets('authLogoWidthFor encolhe em viewport baixa', (tester) async {
    late double shortWidth;
    late double tallWidth;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 640)),
          child: Builder(
            builder: (context) {
              shortWidth = authLogoWidthFor(context, withTagline: true);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 900)),
          child: Builder(
            builder: (context) {
              tallWidth = authLogoWidthFor(context, withTagline: true);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(shortWidth, lessThan(tallWidth));
    expect(tallWidth, kAuthFormLogoWidth);
    expect(shortWidth, 104.0);
  });

  testWidgets('authScrollPadding inclui safe area inferior', (tester) async {
    late EdgeInsets padding;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 840),
            padding: EdgeInsets.only(bottom: 24),
            viewPadding: EdgeInsets.only(bottom: 24),
          ),
          child: Builder(
            builder: (context) {
              padding = authScrollPadding(context, bottomExtra: 20);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(padding.bottom, greaterThanOrEqualTo(44));
    expect(padding.left, 22);
  });
}
