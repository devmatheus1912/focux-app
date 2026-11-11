import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/curated_brand_palettes.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/fx_icons.dart';

/// Paletas curadas em grade (5 por linha): amostra redonda com gradiente
/// primária → secundária e marca de escolhida; o nome da escolhida embaixo.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 8,
            mainAxisExtent: 52,
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
              child: InkResponse(
                onTap: onSelect == null ? null : () => onSelect!(p),
                radius: 28,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 48,
                    height: 48,
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
                              FxIcons.check,
                              size: 22,
                              color: CuratedBrandPalette.readableOn(p.primary),
                            )
                            : null,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Nome só da escolhida, numa linha embaixo da grade.
        Text(
          '${selecionada.name} · ${selecionada.subtitle}',
          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
        ),
      ],
    );
  }
}
