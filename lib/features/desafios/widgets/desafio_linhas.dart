import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_barra_progresso.dart';
import '../../../core/widgets/fx_selo_glifos.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../evolucao/data/meta_corporal.dart';
import '../../evolucao/widgets/conquista_selo.dart';
import '../data/desafio_repository.dart';
import '../utils/desafio_display.dart';

/// Linha da lista de desafios (personal e aluno): título, a regra numa
/// frase e, à direita, o líder com o número dele.
class DesafioLinha extends StatelessWidget {
  const DesafioLinha({super.key, required this.desafio, required this.onTap});

  final Desafio desafio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lider = desafioLiderLabel(desafio);
    return FxSatelliteListTile(
      title: desafio.titulo,
      subtitle: Text(desafioLinhaLista(desafio)),
      trailing:
          lider == null
              ? null
              : Text(
                lider,
                style: FocuxHubTypography.rotulo(
                  color: ShellChrome.of(context).mute,
                ),
              ),
      onTap: onTap,
    );
  }
}

/// Uma posição do ranking: lugar (coroa no 1º, halteres no 2º e 3º), nome,
/// a barra até a meta e "7 de 12". Quem bateu a meta ganha o ✓.
class DesafioLinhaRanking extends StatelessWidget {
  const DesafioLinhaRanking({
    super.key,
    required this.posicao,
    required this.entrada,
    required this.meta,
    this.voce = false,
    this.onTap,
  });

  final int posicao;
  final DesafioLeaderboardEntry entrada;
  final int meta;
  final bool voce;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final n = entrada.pontos;
    final bateu = meta > 0 && n >= meta;
    final nome = voce ? 'Você' : desafioLeaderboardName(entrada.alunoNome);
    final podio = posicao < 3 && n > 0;
    return Semantics(
      button: onTap != null,
      label:
          '${posicao + 1}º lugar, $nome, ${desafioProgresso(n, meta)}${bateu ? ', meta batida' : ''}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: TokensStrip.s2,
            horizontal: TokensStrip.s1,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child:
                    podio
                        ? ConquistaSelo(
                          tipo:
                              posicao == 0
                                  ? ConquistaTipo.recorde
                                  : ConquistaTipo.meta,
                          glifo:
                              posicao == 0
                                  ? FxSeloGlifo.coroa
                                  : FxSeloGlifo.halteresCruzados,
                          tamanho: 32,
                        )
                        : Text(
                          '${posicao + 1}º',
                          textAlign: TextAlign.center,
                          style: FocuxHubTypography.rotulo(color: chrome.mute),
                        ),
              ),
              const SizedBox(width: TokensStrip.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.body(
                        color: voce ? primary : chrome.ink,
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s1),
                    FxBarraProgresso(
                      fracao: desafioFracao(n, meta),
                      cor: bateu ? EagleTokens.good : primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TokensStrip.s3),
              Text(
                desafioProgresso(n, meta),
                style: FocuxHubTypography.rotulo(color: chrome.mute),
              ),
              if (bateu) ...[
                const SizedBox(width: TokensStrip.s1),
                const Icon(
                  FxIcons.checkPequeno,
                  size: 16,
                  color: EagleTokens.good,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
