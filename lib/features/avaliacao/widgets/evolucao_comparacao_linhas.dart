import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/pt.dart';
import '../data/avaliacao_repository.dart';
import '../utils/evolucao_comparativo_display.dart';

/// Composição corporal e, em cartão único, início e atual de cada métrica.
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
    final dias = evolucaoComparativoDias(primeira.avaliadoEm, atual.avaliadoEm);
    final gordura = atual.percGordura;
    final massa = atual.percMassa ?? atual.massaMuscular;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (gordura != null && massa != null) ...[
          _Composicao(gordura: gordura, massa: massa),
          const SizedBox(height: TokensStrip.s3),
        ],
        Container(
          decoration: fxListCardDecoration(context),
          child: Column(
            children: [
              for (final (i, m) in metricas.where((m) => m.visivel).indexed) ...[
                if (i > 0) Divider(height: 1, color: ShellChrome.of(context).line),
                _Linha(
                  metrica: m,
                  suspeita: evolucaoComparativoSuspeita(m, dias),
                ),
              ],
            ],
          ),
        ),
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
                // Stretch: ColoredBox sem filho encolhe para altura 0 numa Row.
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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

/// Nome, "90,0 → 105,0 kg" e a diferença à direita. Sem cor: subir ou descer
/// depende do objetivo.
class _Linha extends StatelessWidget {
  const _Linha({required this.metrica, this.suspeita = false});

  final EvolucaoComparativoMetrica metrica;

  /// Variação fora do comum para o intervalo: marca "Confira".
  final bool suspeita;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final temDois = metrica.primeira != null && metrica.atual != null;
    final inicio = evolucaoComparativoFmtValor(metrica.primeira, metrica.unidade);
    final atual = evolucaoComparativoFmtValor(metrica.atual, metrica.unidade);
    final linha =
        temDois
            ? '${evolucaoComparativoFmtNum(metrica.primeira)} → $atual'
            : ptS.comparacaoUmRegistro(metrica.primeira == null ? atual : inicio);
    final rotulo = ptS.comparacaoLinha(metrica.label, inicio, atual);
    final alerta = chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn;
    return Semantics(
      label: suspeita ? ptS.comparacaoConfiraA11y(rotulo) : rotulo,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s3),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metrica.label,
                    style: FocuxHubTypography.cardTitle(color: chrome.ink),
                  ),
                  Text(
                    linha,
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  ),
                ],
              ),
            ),
            if (temDois)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    evolucaoComparativoDiferenca(metrica),
                    style: FocuxHubTypography.metric(
                      color: chrome.ink,
                      fontSize: TokensStrip.fontBody,
                    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                  if (suspeita)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: alerta),
                        const SizedBox(width: 2),
                        Text(ptS.comparacaoConfira, style: FocuxHubTypography.chip(alerta)),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
