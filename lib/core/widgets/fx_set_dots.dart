import 'package:flutter/material.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import '../theme/fx_icons.dart';

/// Uma série na linha de bolinhas: [detalhe] ("10 kg · 10") só nas já feitas.
class FxSetDot {
  const FxSetDot({
    required this.numero,
    required this.feita,
    this.detalhe,
    this.aquecimento = false,
    this.rotulo,
    this.marca = false,
    this.nome,
  });

  final int numero;
  final bool feita;
  final String? detalhe;

  /// Aquecimento e ajuste: não contam, a bolinha fica vazada mesmo feita.
  final bool aquecimento;

  /// O que vai na bolinha ("A", "1", "B"); nulo = o [numero].
  final String? rotulo;

  /// Ponto embaixo da bolinha: a série tem técnica (drop-set, pico…).
  final bool marca;

  /// Nome para o leitor de tela ("Válida 4, drop-set"); nulo = "Série N".
  final String? nome;
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
      alignment: WrapAlignment.start,
      spacing: TokensStrip.s1,
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
        '${serie.nome ?? 'Série ${serie.numero}'}, $estado'
        '${serie.detalhe == null ? '' : ', ${serie.detalhe}'}';
    final rotulo = serie.rotulo ?? (serie.aquecimento ? 'A' : '${serie.numero}');
    // Aquecimento feito continua vazado: feito, mas não conta.
    final cheia = feita && !serie.aquecimento;
    final letra = int.tryParse(rotulo) == null;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: TokensStrip.prefersReducedMotion(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cheia ? accent : Colors.transparent,
                border: Border.all(
                  color: feita || atual ? accent : chrome.lineStrong,
                  width: atual ? 2.5 : 1.5,
                ),
              ),
              // Ao registrar, a marca entra com uma escala curta.
              child: AnimatedSwitcher(
                duration: TokensStrip.prefersReducedMotion(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                transitionBuilder:
                    (child, animacao) =>
                        ScaleTransition(scale: animacao, child: child),
                // Feita: ✓ nas válidas; "A"/"B" ficam (dizem o que foi feito).
                child:
                    feita && !letra
                        ? const Icon(
                          FxIcons.checkPequeno,
                          key: ValueKey('feita'),
                          size: 16,
                          color: Colors.white,
                        )
                        : Text(
                          rotulo,
                          key: ValueKey('numero-${serie.numero}-$feita'),
                          style: FocuxHubTypography.chip(
                            cheia ? Colors.white : feita || atual ? accent : chrome.mute,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 2),
            if (serie.marca)
              Container(
                key: ValueKey('marca-${serie.numero}'),
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
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
