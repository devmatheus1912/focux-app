import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/brand_palette.dart';
import 'package:focux_app/core/theme/brand_style.dart';
import 'package:focux_app/core/theme/curated_brand_palettes.dart';
import 'package:focux_app/core/theme/focux_contrast.dart';

const _fundoClaro = Color(0xFFF6F4FA);
const _fundoEscuro = Color(0xFF14161A);

void main() {
  group('BrandStyle', () {
    test('lê o valor do backend e cai no Clássico quando não conhece', () {
      expect(BrandStyle.fromApi('CINEMATOGRAFICO'), BrandStyle.cinematografico);
      expect(BrandStyle.fromApi(' minimalista '), BrandStyle.minimalista);
      expect(BrandStyle.fromApi('CLASSICO'), BrandStyle.classico);
      expect(BrandStyle.fromApi(null), BrandStyle.classico);
      expect(BrandStyle.fromApi('qualquer'), BrandStyle.classico);
    });

    test(
      'só o Cinematográfico usa gradiente, acento secundário e fundo tingido',
      () {
        expect(BrandStyle.cinematografico.usaGradiente, isTrue);
        expect(BrandStyle.cinematografico.usaAcentoSecundario, isTrue);
        expect(BrandStyle.cinematografico.tingeFundo, isTrue);
        for (final e in [BrandStyle.classico, BrandStyle.minimalista]) {
          expect(e.usaGradiente, isFalse);
          expect(e.usaAcentoSecundario, isFalse);
          expect(e.tingeFundo, isFalse);
        }
      },
    );

    test('o valor de ida e volta é estável', () {
      for (final e in BrandStyle.values) {
        expect(BrandStyle.fromApi(e.api), e);
      }
    });
  });

  group('derivados em todas as paletas curadas', () {
    for (final paleta in CuratedBrandPalette.premium) {
      for (final escuro in [false, true]) {
        final fundo = escuro ? _fundoEscuro : _fundoClaro;
        test('${paleta.name} (${escuro ? 'escuro' : 'claro'})', () {
          final acento = BrandPalette.secondaryAccent(
            paleta.secondary,
            paleta.primary,
            dark: escuro,
            background: fundo,
          );
          // ícone/anel/selo precisa de 3:1 com o fundo, sempre
          expect(
            FocuxContrast.contrastRatio(acento, fundo),
            greaterThanOrEqualTo(FocuxContrast.wcagAaLarge),
            reason: '${paleta.name}: acento ilegível',
          );

          final g = BrandPalette.gradient(
            paleta.primary,
            paleta.secondary,
            dark: escuro,
          );
          // gradiente só em opacidade baixa: o texto por cima continua legível
          for (final c in g.colors) {
            expect(c.a, lessThanOrEqualTo(0.30));
          }
          final tinta = BrandPalette.surfaceTint(paleta.primary, dark: escuro);
          expect(tinta.a, lessThanOrEqualTo(0.06 + 1e-6));
        });
      }
    }
  });

  test('sem contraste na secundária, cai para o acento da primária', () {
    // secundária quase igual ao fundo claro: não serve de ícone
    const quaseBranca = Color(0xFFF8F6FB);
    final acento = BrandPalette.secondaryAccent(
      quaseBranca,
      const Color(0xFF0B4F5C),
      dark: false,
      background: _fundoClaro,
    );
    expect(
      FocuxContrast.contrastRatio(acento, _fundoClaro),
      greaterThanOrEqualTo(FocuxContrast.wcagAaLarge),
    );
  });
}
