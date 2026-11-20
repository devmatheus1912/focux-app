import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/app_theme.dart';
import 'package:focux_app/core/theme/brand_palette.dart';
import 'package:focux_app/core/theme/chao_da_marca.dart';
import 'package:focux_app/core/theme/focux_contrast.dart';
import 'package:focux_app/core/widgets/fx_chao.dart';

/// Escuro da marca (20/11/2026): petróleo na marca Focux, grafite neutro na
/// marca própria. A cor do personal fica nos destaques, nunca no fundo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('marca Focux (ou nenhuma) dá o petróleo', () {
    expect(tonsEscurosDa(null), TonsEscuros.focux);
    expect(tonsEscurosDa(BrandPalette.defaultPrimary), TonsEscuros.focux);
    expect(tonsEscurosDa(const Color(0xFF0E93A8)), TonsEscuros.focux);
    expect(TonsEscuros.focux.chao, const Color(0xFF0A1A1F));
  });

  test('qualquer outra marca dá o grafite neutro', () {
    for (final cor in [
      const Color(0xFF1E3A8A),
      const Color(0xFF7A1F3D),
      const Color(0xFFEA580C),
      const Color(0xFF777777),
    ]) {
      expect(tonsEscurosDa(cor), TonsEscuros.grafite, reason: '$cor');
    }
    expect(
      HSLColor.fromColor(TonsEscuros.grafite.chao).saturation,
      lessThan(0.2),
    );
  });

  test('texto branco passa AA nas superfícies dos dois tons', () {
    for (final tons in [TonsEscuros.focux, TonsEscuros.grafite]) {
      expect(
        FocuxContrast.meetsWcagAa(Colors.white, tons.superficieAlta),
        isTrue,
      );
    }
  });

  test('o tema escuro leva os tons da marca', () {
    final focux = AppTheme.buildDarkTheme(BrandPalette.defaultPrimary);
    final propria = AppTheme.buildDarkTheme(const Color(0xFF7A1F3D));
    expect(TonsEscuros.de(focux).chao, TonsEscuros.focux.chao);
    expect(TonsEscuros.de(propria).chao, TonsEscuros.grafite.chao);
    expect(propria.scaffoldBackgroundColor, TonsEscuros.grafite.chao);
  });

  test('prévia e chão usam a mesma regra', () {
    expect(
      FxChao.corPara(escuro: true, primaria: const Color(0xFF1E3A8A)),
      TonsEscuros.grafite.chao,
    );
    expect(FxChao.corPara(escuro: false), const Color(0xFFF4F6F8));
  });

  test('superfície escura só vem do tema (context.tons)', () {
    // Petróleo fixo numa tela deixa a marca própria com cards de duas cores.
    const permitidos = {
      'lib/core/theme/design_tokens.dart',
      'lib/core/theme/tokens_strip.dart',
      'lib/core/theme/chao_da_marca.dart',
      // Antes do tema e da marca: tela de erro do boot e splash do Focux.
      'lib/main.dart',
      'lib/features/auth/screens/splash_screen.dart',
      // Referência de contraste das paletas prontas (não pinta nada).
      'lib/core/theme/curated_brand_palettes.dart',
    };
    final fixo = RegExp(
      r'EagleTokens\.(darkBg|darkCard|darkCardHi|darkLine|cinematicBgHi)\b|'
      r'TokensStrip\.(cinematicSurface|cinematicBg)\b|0xFF14161A|0xFFF6F4FA',
    );
    final achados = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final caminho = f.path.replaceAll(r'\', '/');
      if (permitidos.contains(caminho)) continue;
      if (fixo.hasMatch(f.readAsStringSync())) achados.add(caminho);
    }
    expect(achados, isEmpty);
  });
}
