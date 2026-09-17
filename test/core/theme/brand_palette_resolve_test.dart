import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/brand_palette.dart';

void main() {
  group('BrandPalette.resolveStoredPrimary', () {
    test('null e vazio → azul petróleo', () {
      expect(
        BrandPalette.resolveStoredPrimary(null),
        BrandPalette.defaultPrimary,
      );
      expect(
        BrandPalette.resolveStoredPrimary(''),
        BrandPalette.defaultPrimary,
      );
    });

    test('cyan legado → azul petróleo', () {
      expect(
        BrandPalette.resolveStoredPrimary('#13C2C2'),
        BrandPalette.defaultPrimary,
      );
      expect(
        BrandPalette.resolveStoredPrimary('#1ec8c8'),
        BrandPalette.defaultPrimary,
      );
      expect(
        BrandPalette.resolveStoredPrimary(BrandPalette.legacyPrimaryHex),
        BrandPalette.defaultPrimary,
      );
    });

    test('petróleo atual permanece', () {
      expect(
        BrandPalette.resolveStoredPrimary('#0B4F5C'),
        BrandPalette.defaultPrimary,
      );
    });

    test('white-label customizado preserva', () {
      expect(
        BrandPalette.resolveStoredPrimary('#312E81'),
        const Color(0xFF312E81),
      );
    });
  });

  group('BrandPalette.resolveStoredSecondary', () {
    test('legado → defaultSecondary', () {
      expect(
        BrandPalette.resolveStoredSecondary('#007D8A'),
        BrandPalette.defaultSecondary,
      );
      expect(
        BrandPalette.resolveStoredSecondary('#0097A7'),
        BrandPalette.defaultSecondary,
      );
    });

    test('custom preserva', () {
      expect(
        BrandPalette.resolveStoredSecondary('#C9A962'),
        const Color(0xFFC9A962),
      );
    });
  });

  test('isDefaultBrandColors cobre legado e petróleo', () {
    expect(
      BrandPalette.isDefaultBrandColors(
        corPrimaria: '#13C2C2',
        corSecundaria: '#007D8A',
      ),
      isTrue,
    );
    expect(
      BrandPalette.isDefaultBrandColors(
        corPrimaria: '#0B4F5C',
        corSecundaria: '#3D9AAD',
      ),
      isTrue,
    );
    expect(
      BrandPalette.isDefaultBrandColors(
        corPrimaria: '#312E81',
        corSecundaria: '#818CF8',
      ),
      isFalse,
    );
  });
}
