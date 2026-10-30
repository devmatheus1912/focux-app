import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';

/// Um número com rótulo. [alerta] pinta de aviso; zero fica apagado.
class FxMetric {
  const FxMetric({
    required this.valor,
    required this.rotulo,
    this.onTap,
    this.alerta = false,
    this.texto,
  });

  /// Para dinheiro, passe os centavos: zero continua apagado.
  final int valor;

  /// O que aparece no lugar do número (ex.: "R$ 1.250,00"). Sem ele, [valor].
  final String? texto;
  final String rotulo;

  /// Sem [onTap] o número só informa: não é botão para o leitor de tela.
  final VoidCallback? onTap;
  final bool alerta;
}

/// Faixa de números tocáveis. Cada um leva à lista que o explica.
/// Zero nunca ganha cor de alerta: fica apagado.
class FxMetricStrip extends StatelessWidget {
  const FxMetricStrip({super.key, required this.metricas});

  final List<FxMetric> metricas;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Row(
      children: [
        for (final (i, m) in metricas.indexed) ...[
          if (i > 0) const SizedBox(width: TokensStrip.s2),
          Expanded(child: _Tile(metrica: m, chrome: chrome)),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.metrica, required this.chrome});

  final FxMetric metrica;
  final ShellPalette chrome;

  @override
  Widget build(BuildContext context) {
    final zero = metrica.valor == 0;
    final destaque = metrica.alerta && !zero;
    final corNumero = zero
        ? chrome.mute.withValues(alpha: 0.6)
        : destaque
        ? (chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn)
        : chrome.ink;

    return Semantics(
      button: metrica.onTap != null,
      label: '${metrica.texto ?? metrica.valor} ${metrica.rotulo}${destaque ? ', atenção' : ''}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: metrica.onTap,
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          child: Ink(
            decoration: BoxDecoration(
              color: chrome.cardFill,
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
              border: Border.all(
                color: chrome.lineStrong,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: TokensStrip.s2,
              vertical: TokensStrip.s3,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      metrica.texto ?? '${metrica.valor}',
                      maxLines: 1,
                      style: FocuxHubTypography.cardTitle(color: corNumero).copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: TokensStrip.s1),
                  Text(
                    metrica.rotulo,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.cardSubtitle(color: chrome.mute),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
