import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/pt.dart';
import '../data/avaliacao_repository.dart';
import '../utils/evolucao_comparativo_display.dart';

/// Início e atual de cada métrica, com a barra entre os dois valores.
class EvolucaoComparacaoLinhas extends StatelessWidget {
  const EvolucaoComparacaoLinhas({
    super.key,
    required this.primeira,
    required this.atual,
  });

  final SnapshotAvaliacao primeira;
  final SnapshotAvaliacao atual;

  @override
  Widget build(BuildContext context) {
    final metricas = evolucaoComparativoMetricas(
      primeira: primeira,
      atual: atual,
    );
    final gordura = atual.percGordura;
    final massa = atual.percMassa ?? atual.massaMuscular;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (gordura != null && massa != null) ...[
          _Composicao(gordura: gordura, massa: massa),
          const SizedBox(height: TokensStrip.s3),
        ],
        for (final m in metricas) ...[
          _Linha(metrica: m),
          const SizedBox(height: TokensStrip.s2),
        ],
      ],
    );
  }
}

class _Composicao extends StatelessWidget {
  const _Composicao({required this.gordura, required this.massa});

  final double gordura;
  final double massa;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final total = (gordura + massa) < 100 ? 100.0 : gordura + massa;
    final texto = ptS.comparacaoComposicao(
      evolucaoComparativoFmtNum(gordura),
      evolucaoComparativoFmtNum(massa),
    );
    return Semantics(
      label: texto,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(TokensStrip.s3),
        decoration: fxListCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ptS.comparacaoComposicaoTitulo,
              style: FocuxHubTypography.chip(chrome.mute),
            ),
            const SizedBox(height: TokensStrip.s2),
            ClipRRect(
              borderRadius: BorderRadius.circular(TokensStrip.s1),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    Expanded(
                      flex: (gordura * 10).round(),
                      child: ColoredBox(
                        color: primary.withValues(alpha: 0.4),
                      ),
                    ),
                    Expanded(
                      flex: (massa * 10).round(),
                      child: ColoredBox(color: primary),
                    ),
                    if (total > gordura + massa)
                      Expanded(
                        flex: ((total - gordura - massa) * 10).round(),
                        child: ColoredBox(color: chrome.line),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: TokensStrip.s2),
            Text(texto, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
          ],
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.metrica});

  final EvolucaoComparativoMetrica metrica;

  /// De 0 a 1: onde cada ponta fica na barra, com folga para mudança pequena.
  (double, double) _pontas() {
    final a = metrica.primeira!;
    final b = metrica.atual!;
    final menor = a < b ? a : b;
    final maior = a < b ? b : a;
    if (menor == maior) return (0.5, 0.5);
    return (a == menor ? 0.15 : 0.85, b == menor ? 0.15 : 0.85);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final temDois = metrica.primeira != null && metrica.atual != null;
    final inicio = evolucaoComparativoFmtValor(metrica.primeira, metrica.unidade);
    final atual = evolucaoComparativoFmtValor(metrica.atual, metrica.unidade);
    final delta = evolucaoComparativoDelta(
      primeira: metrica.primeira,
      atual: metrica.atual,
      menorEMelhor: metrica.menorEMelhor,
    );
    return Semantics(
      label: ptS.comparacaoLinha(metrica.label, inicio, atual),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(TokensStrip.s3),
        decoration: fxListCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    metrica.label,
                    style: FocuxHubTypography.cardTitle(color: chrome.ink),
                  ),
                ),
                if (temDois)
                  Text(
                    delta.text,
                    style: FocuxHubTypography.metric(
                      color: chrome.mute,
                      fontSize: TokensStrip.fontBody,
                    ),
                  ),
              ],
            ),
            if (temDois) ...[
              const SizedBox(height: TokensStrip.s2),
              SizedBox(
                height: 14,
                child: CustomPaint(
                  painter: _BarraPainter(
                    pontas: _pontas(),
                    trilho: chrome.line,
                    cor: primary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: TokensStrip.s1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  metrica.primeira == null ? '' : inicio,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
                Text(
                  metrica.atual == null ? '' : atual,
                  style: FocuxHubTypography.body(color: chrome.ink),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraPainter extends CustomPainter {
  const _BarraPainter({
    required this.pontas,
    required this.trilho,
    required this.cor,
  });

  final (double, double) pontas;
  final Color trilho;
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final linha =
        Paint()
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linha..color = trilho);
    final inicio = Offset(size.width * pontas.$1, y);
    final fim = Offset(size.width * pontas.$2, y);
    canvas.drawLine(inicio, fim, linha..color = cor);
    canvas.drawCircle(inicio, 5, Paint()..color = cor.withValues(alpha: 0.4));
    canvas.drawCircle(fim, 7, Paint()..color = cor);
  }

  @override
  bool shouldRepaint(_BarraPainter old) =>
      old.pontas != pontas || old.trilho != trilho || old.cor != cor;
}
