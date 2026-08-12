import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/focux_hub_typography.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';

void main() {
  testWidgets('FocuxHubTypography roles espelham Perfil', (tester) async {
    late TextTheme textTheme;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            textTheme = Theme.of(context).textTheme;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final page = FocuxHubTypography.pageTitle(
      tester.element(find.byType(SizedBox)),
      color: Colors.black,
    );
    expect(page.fontWeight, FontWeight.w900);
    expect(page.height, 1.05);
    expect(page.fontSize, textTheme.titleLarge?.fontSize);

    final section = FocuxHubTypography.sectionTitle(
      tester.element(find.byType(SizedBox)),
      color: Colors.black,
    );
    expect(section.fontWeight, FontWeight.w800);
    expect(section.letterSpacing, -0.2);
    expect(section.fontSize, textTheme.titleMedium?.fontSize);

    final eyebrow = FocuxHubTypography.eyebrow(
      tester.element(find.byType(SizedBox)),
      color: Colors.teal,
    );
    expect(eyebrow.fontWeight, FontWeight.w800);
    expect(eyebrow.letterSpacing, 0.1);

    final chip = FocuxHubTypography.chip(Colors.teal);
    expect(chip.fontSize, TokensStrip.fontBodySm - 2);
    expect(chip.fontWeight, FontWeight.w800);

    expect(FocuxHubTypography.metricEm, TokensStrip.fontBody + 3);
    expect(FocuxHubTypography.metricLg, TokensStrip.fontH2);

    final metric = FocuxHubTypography.metric(
      color: Colors.black,
      fontSize: FocuxHubTypography.metricEm,
    );
    expect(metric.fontSize, FocuxHubTypography.metricEm);
  });
}
