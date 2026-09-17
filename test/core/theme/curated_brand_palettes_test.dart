import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/brand_palette.dart';
import 'package:focux_app/core/theme/curated_brand_palettes.dart';
import 'package:focux_app/core/theme/focux_contrast.dart';

void main() {
  test('all curated palettes are safe pairs with readable primary', () {
    for (final palette in CuratedBrandPalette.premium) {
      expect(
        CuratedBrandPalette.isReadablePrimary(palette.primary),
        isTrue,
        reason: palette.name,
      );
      expect(
        CuratedBrandPalette.isSafePair(palette.primary, palette.secondary),
        isTrue,
        reason: palette.name,
      );
      expect(
        palette.primary,
        isNot(equals(palette.secondary)),
        reason: palette.name,
      );
    }
  });

  test('resolve maps unknown colors to closest curated palette', () {
    final resolved = CuratedBrandPalette.resolve(
      const Color(0xFF1A2332),
      const Color(0xFFC9A962),
    );
    expect(resolved.id, 'midnight_gold');
  });

  test('safePrimary keeps dark curated brand neutrals', () {
    expect(
      CuratedBrandPalette.safePrimary(const Color(0xFF1A2332)),
      const Color(0xFF1A2332),
    );
    expect(
      CuratedBrandPalette.safePrimary(const Color(0xFF171717)),
      const Color(0xFF171717),
    );
    expect(
      CuratedBrandPalette.safePrimary(const Color(0xFFF5F5F5)),
      isNot(equals(const Color(0xFFF5F5F5))),
    );
  });

  test('dark chrome accent stays visible on mesh and keeps white labels', () {
    const mesh = Color(0xFF0B0E14);
    const white = Color(0xFFFFFFFF);
    for (final palette in CuratedBrandPalette.premium) {
      final lightChrome = palette.chromeFor(dark: false);
      expect(
        lightChrome,
        palette.primary,
        reason: '${palette.name} light keeps stored primary',
      );

      final darkChrome = palette.chromeFor(dark: true);
      expect(
        FocuxContrast.contrastRatio(darkChrome, mesh),
        greaterThanOrEqualTo(FocuxContrast.wcagAaLarge),
        reason: '${palette.name} icon on dark mesh',
      );
      if (darkChrome != palette.primary) {
        expect(
          FocuxContrast.contrastRatio(white, darkChrome),
          greaterThanOrEqualTo(FocuxContrast.wcagAaNormal),
          reason: '${palette.name} white label on remapped chrome',
        );
      }
    }
  });

  test('dark chrome re-entry keeps brand secondary, not Focux default', () {
    for (final palette in CuratedBrandPalette.premium) {
      final chrome = palette.chromeFor(dark: true);
      final second = CuratedBrandPalette.safeSecondaryFor(
        chrome,
        palette.secondary,
      );
      expect(
        second,
        palette.secondary,
        reason: '${palette.name} secondary after chrome re-entry',
      );
      if (palette.id != CuratedBrandPalette.focuxDefault.id) {
        expect(
          second,
          isNot(BrandPalette.defaultSecondary),
          reason: '${palette.name} must not snap to Focux brand secondary',
        );
      }
      final again = CuratedBrandPalette.chromeAccent(
        chrome,
        second,
        dark: true,
      );
      if (palette.id != CuratedBrandPalette.focuxDefault.id) {
        expect(
          again,
          isNot(BrandPalette.defaultPrimary),
          reason: '${palette.name} second pass must not snap to Focux primary',
        );
      }
      expect(
        FocuxContrast.contrastRatio(again, const Color(0xFF0B0E14)),
        greaterThanOrEqualTo(FocuxContrast.wcagAaLarge),
        reason: '${palette.name} second pass still reads on mesh',
      );
    }
  });
}
