import 'package:flutter/material.dart';

import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/utils/aluno_ritmo_linha.dart';
import '../utils/historico_detalhe_texts.dart';
import '../utils/historico_fichas.dart';
import '../utils/treinos_hub_texts.dart';
import '../utils/treinos_hub_view.dart';

/// Loading do histórico: cabeçalho de semana e quatro linhas.
class HistoricoSkeleton extends StatelessWidget {
  const HistoricoSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: S.of(context).historicoCarregando,
      excludeSemantics: true,
      child: const FxContentWidthLimiter(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(TokensStrip.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkeletonLoader(width: 160, height: 16),
              SizedBox(height: TokensStrip.s2),
              SkeletonLoader(height: 56, borderRadius: TokensStrip.rCard),
              SizedBox(height: TokensStrip.s1),
              SkeletonLoader(height: 56, borderRadius: TokensStrip.rCard),
              SizedBox(height: TokensStrip.s1),
              SkeletonLoader(height: 56, borderRadius: TokensStrip.rCard),
              SizedBox(height: TokensStrip.s1),
              SkeletonLoader(height: 56, borderRadius: TokensStrip.rCard),
            ],
          ),
        ),
      ),
    );
  }
}

/// Maior carga recente: exercício e número, na largura da tela.
class HistoricoGanhoCard extends StatelessWidget {
  const HistoricoGanhoCard({super.key, required this.linha});

  final AlunoRitmoLinha linha;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final s = S.of(context);
    return Semantics(
      container: true,
      label: '${s.historicoMaiorCarga}. ${linha.sobrancelha}. ${linha.titulo}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(TokensStrip.s3),
        decoration: fxListCardDecoration(context),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.historicoMaiorCarga,
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    linha.sobrancelha,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.cardTitle(color: chrome.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(width: TokensStrip.s3),
            Text(
              linha.titulo,
              style: FocuxHubTypography.metric(color: chrome.ink, fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sessão do histórico: data à esquerda, nome e o que foi feito.
class HistoricoSessaoRow extends StatelessWidget {
  const HistoricoSessaoRow({
    super.key,
    required this.recente,
    required this.onTap,
  });

  final TreinoRecente recente;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final nome = recente.execucao.treinoNome;
    final detalhe = treinosRecenteDetalhe(s, recente);
    final parcial = recente.execucao.parcial;
    final quando = recente.quando;
    return Semantics(
      button: true,
      label: [
        s.treinosDiaData(quando),
        nome,
        detalhe,
        if (parcial) s.historicoParcial,
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TokensStrip.s3,
              vertical: TokensStrip.s2,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Column(
                    children: [
                      Text(
                        '${quando.day}',
                        style: FocuxHubTypography.metric(
                          color: chrome.ink,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        historicoMesCurto(quando.month),
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TokensStrip.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FocuxHubTypography.cardTitle(color: chrome.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detalhe,
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                    ],
                  ),
                ),
                if (parcial) ...[
                  const SizedBox(width: TokensStrip.s2),
                  FxStatusPill(label: s.historicoParcial, tone: FxPillTone.warning),
                ],
                const SizedBox(width: TokensStrip.s1),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: chrome.mute,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Todos" + uma chip por ficha; `null` = todas.
class HistoricoFiltroFichas extends StatelessWidget {
  const HistoricoFiltroFichas({
    super.key,
    required this.fichas,
    required this.selecionado,
    required this.onSelect,
  });

  final List<HistoricoFicha> fichas;
  final int? selecionado;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = ShellChrome.of(context).isDark;
    Widget chip(String label, int? id) => Padding(
      padding: const EdgeInsets.only(right: TokensStrip.s2),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: FxToggleChip(
          label: label,
          selected: selecionado == id,
          isDark: isDark,
          filledWhenSelected: true,
          onTap: () => onSelect(id),
        ),
      ),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        TokensStrip.s2,
        TokensStrip.s4,
        0,
      ),
      child: Row(
        children: [
          chip(s.historicoFiltroTodos, null),
          for (final f in fichas) chip(f.nome, f.treinoId),
        ],
      ),
    );
  }
}

/// Fim da lista com página seguinte. Ao aparecer, pede a página. Em erro,
/// oferece "Tentar de novo" sem perder o que já carregou.
class HistoricoMaisRodape extends StatefulWidget {
  const HistoricoMaisRodape({
    super.key,
    required this.erro,
    required this.onCarregar,
  });

  final bool erro;
  final VoidCallback onCarregar;

  @override
  State<HistoricoMaisRodape> createState() => _HistoricoMaisRodapeState();
}

class _HistoricoMaisRodapeState extends State<HistoricoMaisRodape> {
  @override
  void initState() {
    super.initState();
    if (!widget.erro) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCarregar();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (!widget.erro) {
      return Semantics(
        container: true,
        liveRegion: true,
        label: s.historicoCarregandoMais,
        excludeSemantics: true,
        child: const SkeletonLoader(
          height: 56,
          borderRadius: TokensStrip.rCard,
        ),
      );
    }
    final chrome = ShellChrome.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            s.historicoMaisErro,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
        ),
        const SizedBox(width: TokensStrip.s2),
        FxTonalButton(
          label: s.historicoTentarDeNovo,
          icon: Icons.refresh_rounded,
          compact: true,
          onPressed: widget.onCarregar,
        ),
      ],
    );
  }
}
