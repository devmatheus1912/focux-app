import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/curated_brand_palettes.dart';

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
}
