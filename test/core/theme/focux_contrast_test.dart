import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/curated_brand_palettes.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/theme/focux_contrast.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';

void main() {
  test('EagleTokens light surfaces meet WCAG AA for body text', () {
    final bodyPairs = [
      (EagleTokens.ink, EagleTokens.paper),
      (EagleTokens.ink, EagleTokens.card),
      (EagleTokens.ink, EagleTokens.brandSoft),
      (FocuxContrast.readableOn(EagleTokens.brand), EagleTokens.brand),
    ];

    for (final (fg, bg) in bodyPairs) {
      expect(
        FocuxContrast.meetsWcagAa(fg, bg),
        isTrue,
        reason: '${fg.toARGB32().toRadixString(16)} on ${bg.toARGB32().toRadixString(16)}',
      );
    }

    final readableMuted =
        TokensStrip.textPrimary.withValues(alpha: 0.76);
    final readableCaption =
        TokensStrip.textPrimary.withValues(alpha: 0.72);
    for (final (fg, bg, label) in [
      (readableMuted, EagleTokens.card, 'readableMuted'),
      (readableCaption, EagleTokens.card, 'readableCaption'),
      (readableMuted, EagleTokens.paper, 'readableMuted/paper'),
    ]) {
      expect(
        FocuxContrast.meetsWcagAa(fg, bg),
        isTrue,
        reason: '$label ${fg.toARGB32().toRadixString(16)} on ${bg.toARGB32().toRadixString(16)}',
      );
    }
  });

  test('EagleTokens semantic accents meet WCAG AA large text on surfaces', () {
    final accentPairs = [
      (EagleTokens.semanticGood(), EagleTokens.card),
      (EagleTokens.semanticWarn(), EagleTokens.card),
      (EagleTokens.semanticBad(), EagleTokens.card),
      (EagleTokens.semanticGood(), EagleTokens.semanticGoodSoft()),
      (EagleTokens.semanticWarn(), EagleTokens.semanticWarnSoft()),
      (EagleTokens.semanticBad(), EagleTokens.semanticBadSoft()),
    ];

    for (final (fg, bg) in accentPairs) {
      expect(
        FocuxContrast.meetsWcagAa(fg, bg, largeText: true),
        isTrue,
        reason: 'accent ${fg.toARGB32().toRadixString(16)} on ${bg.toARGB32().toRadixString(16)}',
      );
    }
  });

  test('EagleTokens dark surfaces meet WCAG AA for body text', () {
    final pairs = [
      (EagleTokens.darkInk, EagleTokens.darkBg),
      (EagleTokens.darkInk, EagleTokens.darkCard),
      (EagleTokens.darkInkMute, EagleTokens.darkCard),
      (EagleTokens.semanticGood(isDark: true), EagleTokens.darkCard),
      (EagleTokens.semanticWarn(isDark: true), EagleTokens.darkCard),
      (EagleTokens.semanticBad(isDark: true), EagleTokens.darkCard),
    ];

    for (final (fg, bg) in pairs) {
      expect(
        FocuxContrast.meetsWcagAa(fg, bg),
        isTrue,
        reason: '${fg.toARGB32().toRadixString(16)} on ${bg.toARGB32().toRadixString(16)}',
      );
    }
  });

  test('brand primary on readable foreground meets WCAG AA', () {
    for (final palette in CuratedBrandPalette.premium) {
      final onPrimary = FocuxContrast.readableOn(palette.primary);
      expect(
        FocuxContrast.meetsWcagAa(onPrimary, palette.primary),
        isTrue,
        reason: palette.name,
      );
      expect(
        CuratedBrandPalette.isReadablePrimary(palette.primary),
        isTrue,
        reason: palette.name,
      );
    }
  });

  test('readableOn picks high-contrast ink on light and white on dark', () {
    expect(
      FocuxContrast.readableOn(EagleTokens.paper),
      const Color(0xFF111318),
    );
    expect(
      FocuxContrast.readableOn(EagleTokens.darkBg),
      Colors.white,
    );
  });
}
