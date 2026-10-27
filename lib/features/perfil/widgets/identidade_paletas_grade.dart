import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/curated_brand_palettes.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';

/// Paletas curadas em grade de amostras (3 por linha): amostra redonda com
/// gradiente primária → secundária, nome embaixo e marca de escolhida.
class IdentidadePaletasGrade extends StatelessWidget {
  const IdentidadePaletasGrade({
    super.key,
    required this.selecionada,
    this.onSelect,
  });

  final CuratedBrandPalette selecionada;
  final ValueChanged<CuratedBrandPalette>? onSelect;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        mainAxisExtent: 108,
      ),
      itemCount: CuratedBrandPalette.premium.length,
      itemBuilder: (context, i) {
        final p = CuratedBrandPalette.premium[i];
        final escolhida = p.id == selecionada.id;
        return Semantics(
          button: true,
          selected: escolhida,
          label: '${p.name}. ${p.subtitle}',
          excludeSemantics: true,
          child: InkWell(
            onTap: onSelect == null ? null : () => onSelect!(p),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [BrandPalette.deep(p.primary), p.primary, p.secondary],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    border: Border.all(
                      color: escolhida ? p.chromeFor(dark: chrome.isDark) : chrome.line,
                      width: escolhida ? 3 : 1,
                    ),
                  ),
                  child:
                      escolhida
                          ? Icon(
                            Icons.check_rounded,
                            size: 26,
                            color: CuratedBrandPalette.readableOn(p.primary),
                          )
                          : null,
                ),
                const SizedBox(height: 6),
                Text(
                  p.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.chip(chrome.ink).copyWith(
                    fontWeight: escolhida ? FontWeight.w800 : FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
