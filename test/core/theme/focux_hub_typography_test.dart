import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/focux_hub_typography.dart';
import 'package:focux_app/core/theme/focux_typography.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  const ink = Color(0xFF1A1A2E);

  test('type scale preserves visual hierarchy ordering', () {
    final page = FocuxTypography.display(color: ink);
    final section = FocuxTypography.headline(color: ink);
    final card = FocuxHubTypography.cardTitle(color: ink);
    final caption = FocuxTypography.bodySmall(color: ink);

    expect(page.fontSize, greaterThan(section.fontSize!));
    expect(section.fontSize, greaterThan(card.fontSize!));
    expect(card.fontSize, greaterThanOrEqualTo(caption.fontSize!));
    expect(page.fontSize, TokensStrip.fontH1);
    expect(section.fontSize, TokensStrip.fontH2);
    expect(caption.fontSize, TokensStrip.fontBodySm);
  });

  test('elevation layers are monotonically ordered', () {
    expect(TokensStrip.layerBase, lessThan(TokensStrip.layerRaised));
    expect(TokensStrip.layerRaised, lessThan(TokensStrip.layerSticky));
    expect(TokensStrip.layerSticky, lessThan(TokensStrip.layerOverlay));
    expect(TokensStrip.layerOverlay, lessThan(TokensStrip.layerModal));
  });

  test('elevation layers delegate to TokensStrip shadows', () {
    expect(
      TokensStrip.elevation(TokensStrip.layerBase, dark: false),
      isEmpty,
    );
    expect(
      TokensStrip.elevation(TokensStrip.layerSticky, dark: false),
      isNotEmpty,
    );
  });
}
