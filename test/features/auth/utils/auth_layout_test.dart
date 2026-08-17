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
    expect(padding.left, 24);
  });

  testWidgets('authScrollPadding reserva teclado e rodapé legal', (
    tester,
  ) async {
    late EdgeInsets base;
    late EdgeInsets withFooter;
    late EdgeInsets withKeyboard;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 840),
            viewPadding: EdgeInsets.only(bottom: 24),
            viewInsets: EdgeInsets.zero,
          ),
          child: Builder(
            builder: (context) {
              base = authScrollPadding(context, bottomExtra: 20);
              withFooter = authScrollPadding(
                context,
                bottomExtra: 20,
                ensureFooter: true,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 840),
            viewPadding: EdgeInsets.only(bottom: 24),
            viewInsets: EdgeInsets.only(bottom: 280),
          ),
          child: Builder(
            builder: (context) {
              withKeyboard = authScrollPadding(
                context,
                bottomExtra: 20,
                ensureFooter: true,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(withFooter.bottom, greaterThan(base.bottom));
    expect(withKeyboard.bottom, greaterThan(withFooter.bottom));
  });
}
