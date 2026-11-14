import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/pt.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_aneis.dart';

/// O que o resumo do aluno mostra embaixo de "Meu progresso": a meta quando
/// existe; sem meta, a próxima medida. A semana já está no cartão do treino.
String evolucaoResumoDoAluno(EvolucaoAneis aneis, {String? metaNome}) {
  final l = leiturasDosAneis(aneis, doPersonal: false, metaNome: metaNome);
  final meta = l[1];
  final medidas = l[2];
  return meta.vazio
      ? '${medidas.rotulo}: ${medidas.valor}'
      : '${meta.rotulo}: ${meta.valor}';
}

/// Hoje do aluno: uma linha "Meu progresso" que abre o Meu progresso (os
/// anéis grandes moram lá).
class EvolucaoResumoAluno extends StatelessWidget {
  const EvolucaoResumoAluno({
    super.key,
    required this.aneis,
    required this.onTap,
    this.metaNome,
  });

  final EvolucaoAneis aneis;
  final VoidCallback onTap;
  final String? metaNome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final detalhe = evolucaoResumoDoAluno(aneis, metaNome: metaNome);
    return Semantics(
      button: true,
      label: '${ptS.meuProgressoTitulo}. $detalhe',
      excludeSemantics: true,
      child: _Cartao(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ptS.meuProgressoTitulo,
              style: FocuxHubTypography.cardTitle(color: scheme.onSurface),
            ),
            const SizedBox(height: TokensStrip.s1),
            Text(
              detalhe,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FocuxHubTypography.bodyMuted(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card Corpo do 360: as mesmas leituras da faixa da Evolução, em texto.
/// Meta vazia vira link para definir a meta; o resto do card abre a Evolução.
class EvolucaoResumoPersonal extends StatelessWidget {
  const EvolucaoResumoPersonal({
    super.key,
    required this.aneis,
    required this.onTap,
    required this.pesoLinha,
    this.onDefinirMeta,
    this.metaNome,
  });

  final EvolucaoAneis aneis;
  final VoidCallback onTap;
  final String pesoLinha;
  final VoidCallback? onDefinirMeta;
  final String? metaNome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final leituras = leiturasDosAneis(aneis, doPersonal: true, metaNome: metaNome);
    final estilo = FocuxHubTypography.bodyMuted(color: scheme.onSurface);
    return _Cartao(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, l) in leituras.indexed)
            if (i == 1 && l.vazio && onDefinirMeta != null)
              _LinkDaMeta(leitura: l, estilo: estilo, onTap: onDefinirMeta!)
            else
              Text(
                '${l.rotulo}: ${l.valor}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: estilo,
              ),
          Text(
            '${ptS.evolucaoMetricaPeso}: $pesoLinha',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: estilo,
          ),
        ],
      ),
    );
  }
}

class _LinkDaMeta extends StatelessWidget {
  const _LinkDaMeta({
    required this.leitura,
    required this.estilo,
    required this.onTap,
  });

  final LeituraDoAnel leitura;
  final TextStyle estilo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${leitura.rotulo}: ${leitura.valor}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: '${leitura.rotulo}: ',
                children: [
                  TextSpan(
                    text: leitura.valor,
                    style: FocuxHubTypography.rotulo(color: primary),
                  ),
                ],
              ),
              style: estilo,
            ),
          ),
        ),
      ),
    );
  }
}

/// Moldura de cartão de lista com chevron.
class _Cartao extends StatelessWidget {
  const _Cartao({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(TokensStrip.s3),
          decoration: fxListCardDecoration(context),
          child: Row(
            children: [
              Expanded(child: child),
              Icon(FxIcons.chevronDireita, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
