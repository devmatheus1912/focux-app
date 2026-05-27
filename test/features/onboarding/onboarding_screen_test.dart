import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/brand/focux_brand_copy.dart';
import 'package:focux_app/core/theme/app_theme.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:focux_app/features/onboarding/screens/onboarding_screen.dart';

void main() {
  testWidgets('onboarding exibe toggle personal/aluno e primeiro slide', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildDarkTheme(TokensStrip.neonGlow),
        home: const OnboardingScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Aluno'), findsOneWidget);
    expect(find.text(FocuxBrandCopy.onboardingCtaNext), findsOneWidget);

    await tester.tap(find.text('Aluno'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.textContaining('Execute com timer'), findsOneWidget);
  });
}
