import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import 'fx_loading.dart';

/// Carregamento de tela cheia sobre fundo liso (mesmo do login, sem grade nem
/// malha): `#0B0E14` no escuro e o tom base da malha no claro. Para telas que
/// ainda não têm conteúdo nenhum; listas usam esqueleto.
class FxTelaCarregando extends StatelessWidget {
  const FxTelaCarregando({super.key, this.rotulo});

  final String? rotulo;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final brand = chrome.isDark ? BrandPalette.accent(primary) : primary;
    return ColoredBox(
      color: chrome.isDark ? TokensStrip.cinematicBg : TokensStrip.lightMeshC,
      child: SizedBox.expand(
        child: Semantics(
          liveRegion: true,
          label: rotulo ?? 'Carregando',
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FxLoading(color: brand, size: 32),
                if (rotulo != null) ...[
                  const SizedBox(height: TokensStrip.s3),
                  Text(
                    rotulo!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: chrome.mute,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
