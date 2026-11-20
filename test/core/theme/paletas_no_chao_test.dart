import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/app_theme.dart';
import 'package:focux_app/core/theme/brand_palette.dart';
import 'package:focux_app/core/theme/curated_brand_palettes.dart';
import 'package:focux_app/core/theme/focux_contrast.dart';
import 'package:focux_app/core/theme/shell_chrome.dart';
import 'package:focux_app/core/widgets/fx_chao.dart';
import 'package:google_fonts/google_fonts.dart';

/// Toda paleta lê sobre o chão sólido, nos dois modos, com e sem o tingido
/// do estilo Cinematográfico: texto em AA (4,5:1) e a primária do tema,
/// usada em botões e ícones, em 3:1.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final p in CuratedBrandPalette.premium) {
    for (final escuro in [false, true]) {
      for (final tinge in [false, true]) {
        final caso =
            '${p.id} ${escuro ? 'escuro' : 'claro'}${tinge ? ' tingido' : ''}';
        test(caso, () {
          final chao = FxChao.corPara(
            escuro: escuro,
            tinta: tinge ? p.primary : null,
          );
          final tema = escuro
              ? AppTheme.buildDarkTheme(p.primary, secondary: p.secondary)
              : AppTheme.buildTheme(p.primary, secondary: p.secondary);
          final prim = tema.colorScheme.primary;
          final shell = ShellPalette(escuro, brand: prim);
          double c(Color x) => FocuxContrast.contrastRatio(x, chao);

          expect(c(shell.ink), greaterThanOrEqualTo(4.5), reason: 'texto');
          expect(c(shell.mute), greaterThanOrEqualTo(4.5), reason: 'apoio');
          for (final (nome, cor) in [
            ('título', BrandPalette.sectionHeading(prim, dark: escuro)),
            ('ação', BrandPalette.sectionAction(prim, dark: escuro)),
            ('link', BrandPalette.sectionLink(prim, dark: escuro)),
          ]) {
            expect(c(cor), greaterThanOrEqualTo(4.5), reason: nome);
          }
          expect(c(prim), greaterThanOrEqualTo(3.0), reason: 'primária');
        });
      }
    }
  }
}
