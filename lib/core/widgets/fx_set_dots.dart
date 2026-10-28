import 'package:flutter/material.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';

/// Uma série na linha de bolinhas: [detalhe] ("40 kg × 10") só nas já feitas.
class FxSetDot {
  const FxSetDot({
    required this.numero,
    required this.feita,
    this.detalhe,
    this.aquecimento = false,
  });

  final int numero;
  final bool feita;
  final String? detalhe;
  final bool aquecimento;
}

/// Progresso do exercício em bolinhas: cheia e com o que foi feito, a próxima
/// destacada, as demais vazias. Mostra de relance o que já está registrado.
class FxSetDots extends StatelessWidget {
  const FxSetDots({super.key, required this.series, required this.accent});

  final List<FxSetDot> series;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final proxima = series.indexWhere((s) => !s.feita);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: TokensStrip.s3,
      runSpacing: TokensStrip.s2,
      children: [
        for (var i = 0; i < series.length; i++)
          _Dot(
            serie: series[i],
            accent: accent,
            chrome: chrome,
            atual: i == proxima,
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.serie,
    required this.accent,
    required this.chrome,
    required this.atual,
  });

  final FxSetDot serie;
  final Color accent;
  final ShellPalette chrome;
  final bool atual;

  @override
  Widget build(BuildContext context) {
    final feita = serie.feita;
    final estado =
        feita
            ? 'feita'
            : atual
            ? 'próxima'
            : 'pendente';
    final label =
        'Série ${serie.numero}, $estado'
        '${serie.detalhe == null ? '' : ', ${serie.detalhe}'}';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: feita ? accent : Colors.transparent,
                border: Border.all(
                  color: feita || atual ? accent : chrome.lineStrong,
                  width: atual ? 2.5 : 1.5,
                ),
              ),
              child:
                  feita
                      ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      )
                      : Text(
                        serie.aquecimento ? 'A' : '${serie.numero}',
                        style: FocuxHubTypography.chip(
                          atual ? accent : chrome.mute,
                        ),
                      ),
            ),
            const SizedBox(height: 2),
            Text(
              serie.detalhe ?? ' ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: FocuxHubTypography.cardSubtitle(color: chrome.mute),
            ),
          ],
        ),
      ),
    );
  }
}
