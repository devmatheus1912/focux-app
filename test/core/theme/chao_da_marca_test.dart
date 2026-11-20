import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/brand_palette.dart';
import 'package:focux_app/core/theme/chao_da_marca.dart';
import 'package:focux_app/core/theme/focux_contrast.dart';
import 'package:focux_app/core/widgets/fx_chao.dart';

/// SPEC fundo e marca (20/11/2026): o escuro do app segue a matiz da marca do
/// personal com o brilho do petróleo do Focux.
void main() {
  double luz(Color c) => HSLColor.fromColor(c).lightness;
  double matiz(Color c) => HSLColor.fromColor(c).hue;

  test('marca Focux (ou nenhuma) dá exatamente o petróleo', () {
    expect(tonsEscurosDa(null).chao, const Color(0xFF0A1A1F));
    expect(
      tonsEscurosDa(BrandPalette.defaultPrimary).chao,
      const Color(0xFF0A1A1F),
    );
    expect(
      tonsEscurosDa(const Color(0xFF0E93A8)).linha,
      const Color(0xFF1B3A42),
    );
  });

  test('azul-marinho dá a matiz dele com o brilho do petróleo', () {
    const marinho = Color(0xFF1E3A8A);
    final tons = tonsEscurosDa(marinho);
    expect(matiz(tons.chao), closeTo(matiz(marinho), 3));
    expect(luz(tons.chao), closeTo(0.08, 0.01));
    expect(luz(tons.superficie), closeTo(0.118, 0.01));
    expect(luz(tons.linha), closeTo(0.182, 0.01));
  });

  test('cinza dá escuro neutro', () {
    final tons = tonsEscurosDa(const Color(0xFF777777));
    expect(HSLColor.fromColor(tons.chao).saturation, 0);
  });

  test('texto do escuro passa AA em qualquer matiz', () {
    for (final cor in [
      const Color(0xFF1E3A8A),
      const Color(0xFFB91C1C),
      const Color(0xFF15803D),
      const Color(0xFF7E22CE),
      const Color(0xFFD97706),
    ]) {
      final tons = tonsEscurosDa(cor);
      expect(
        FocuxContrast.meetsWcagAa(Colors.white, tons.superficie),
        isTrue,
        reason: '$cor',
      );
    }
  });

  test('prévia usa o mesmo chão do app', () {
    const marinho = Color(0xFF1E3A8A);
    expect(
      FxChao.corPara(escuro: true, primaria: marinho),
      tonsEscurosDa(marinho).chao,
    );
    expect(FxChao.corPara(escuro: false), const Color(0xFFF4F6F8));
  });

  test('nenhum fundo antigo (#14161A, #F6F4FA) no app', () {
    final antigos = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final texto = f.readAsStringSync();
      if (texto.contains('0xFF14161A') || texto.contains('0xFFF6F4FA')) {
        antigos.add(f.path);
      }
    }
    expect(antigos, isEmpty);
  });
}
