import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/brand_palette.dart';
import 'package:focux_app/core/theme/focux_contrast.dart';

/// Cores que um personal pode escolher: escuras, claras, quentes, frias,
/// neutras e as extremas.
const _cores = <String, Color>{
  'padrão Focux': Color(0xFF0B4F5C),
  'azul': Color(0xFF1E5EFF),
  'verde': Color(0xFF16A34A),
  'vermelho': Color(0xFFDC2626),
  'laranja': Color(0xFFF97316),
  'amarelo': Color(0xFFFACC15),
  'rosa': Color(0xFFEC4899),
  'roxo': Color(0xFF7C3AED),
  'cinza claro': Color(0xFFD1D5DB),
  'branco': Color(0xFFFFFFFF),
  'preto': Color(0xFF000000),
  'ciano vivo': Color(0xFF00E5FF),
};

double _matiz(Color c) => HSLColor.fromColor(c).hue;

void main() {
  for (final entry in _cores.entries) {
    for (final escuro in [false, true]) {
      final modo = escuro ? 'escuro' : 'claro';
      group('cardDeMarca ${entry.key} ($modo)', () {
        final card = BrandPalette.cardDeMarca(entry.value, dark: escuro);

        test('é sólido (opaco) e o texto passa AA nos dois extremos', () {
          expect(card.fundo.a, 1.0);
          expect(card.fundoFim.a, 1.0);
          expect(
            FocuxContrast.contrastRatio(card.sobre, card.fundo),
            greaterThanOrEqualTo(FocuxContrast.wcagAaNormal),
          );
          expect(
            FocuxContrast.contrastRatio(card.sobre, card.fundoFim),
            greaterThanOrEqualTo(FocuxContrast.wcagAaNormal),
          );
        });

        test('o degradê tem a mesma matiz e variação mínima de luminosidade', () {
          final a = HSLColor.fromColor(card.fundo);
          final b = HSLColor.fromColor(card.fundoFim);
          if (a.saturation > 0.05 && b.saturation > 0.05) {
            final diff = (_matiz(card.fundo) - _matiz(card.fundoFim)).abs();
            expect(diff > 180 ? 360 - diff : diff, lessThanOrEqualTo(3));
          }
          expect(
            (a.lightness - b.lightness).abs(),
            lessThanOrEqualTo(BrandPalette.cardDeMarcaVariacao + 0.01),
          );
        });
      });
    }
  }

  test('a matiz da cor escolhida é preservada no topo do card', () {
    const azul = Color(0xFF1E5EFF);
    final card = BrandPalette.cardDeMarca(azul, dark: false);
    final diff = (_matiz(azul) - _matiz(card.fundo)).abs();
    expect(diff > 180 ? 360 - diff : diff, lessThanOrEqualTo(3));
  });

  test('cor já escura entra quase como está (só escurecida o necessário)', () {
    const escura = Color(0xFF0B4F5C);
    final card = BrandPalette.cardDeMarca(escura, dark: false);
    expect(
      HSLColor.fromColor(card.fundo).lightness,
      closeTo(HSLColor.fromColor(escura).lightness, 0.05),
    );
  });

  test('cor clara é escurecida até o texto branco passar', () {
    const amarelo = Color(0xFFFACC15);
    final card = BrandPalette.cardDeMarca(amarelo, dark: false);
    expect(
      HSLColor.fromColor(card.fundo).lightness,
      lessThan(HSLColor.fromColor(amarelo).lightness),
    );
    expect(
      FocuxContrast.contrastRatio(Colors.white, card.fundo),
      greaterThanOrEqualTo(4.5),
    );
  });
}
