import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../utils/historico_detalhe_texts.dart';
import '../utils/historico_detalhe_view.dart';
import '../utils/treinos_hub_texts.dart';

/// Loading do detalhe: resumo, três números e três exercícios.
class HistoricoDetalheSkeleton extends StatelessWidget {
  const HistoricoDetalheSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: S.of(context).historicoDetalheCarregando,
      excludeSemantics: true,
      child: const FxContentWidthLimiter(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(TokensStrip.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkeletonLoader(height: 96, borderRadius: TokensStrip.rCard),
              SizedBox(height: TokensStrip.s3),
              SkeletonLoader(height: 72, borderRadius: TokensStrip.rCard),
              SizedBox(height: TokensStrip.s4),
              SkeletonLoader(width: 120, height: 16),
              SizedBox(height: TokensStrip.s2),
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

/// Duração e comparação com a sessão anterior; sem nada a dizer, não aparece.
class HistoricoResumoCard extends StatelessWidget {
  const HistoricoResumoCard({super.key, required this.view});

  final HistoricoDetalheView view;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final status = historicoDetalheStatus(s, view);
    final duracao = view.duracao;
    final titulo = status ?? (duracao == null ? null : treinosDuracaoTexto(s, duracao));
    final linhas = [
      if (status != null && duracao != null) treinosDuracaoTexto(s, duracao),
      historicoComparacaoTexto(s, view.comparacao),
      historicoDestaqueTexto(s, view),
    ].nonNulls.toList();
    if (titulo == null && linhas.isEmpty) return const SizedBox.shrink();
    return FxStripCard(
      accent: primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titulo != null)
            Text(
              titulo,
              style: FocuxHubTypography.sectionTitle(context, color: chrome.ink),
            ),
          for (final (i, linha) in linhas.indexed) ...[
            if (i > 0 || titulo != null) const SizedBox(height: TokensStrip.s1),
            Text(
              linha,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          ],
        ],
      ),
    );
  }
}

/// Volume (só com carga), séries e exercícios feitos, em um cartão só.
class HistoricoMetricas extends StatelessWidget {
  const HistoricoMetricas({super.key, required this.view});

  final HistoricoDetalheView view;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final volume = view.volumeKg;
    final itens = [
      if (volume != null) (s.historicoVolume, historicoKgTexto(s, volume)),
      (
        s.historicoSeries,
        historicoNDeMTexto(s, view.seriesFeitas, view.seriesPlanejadas),
      ),
      (
        s.historicoExercicios,
        historicoNDeMTexto(s, view.exerciciosFeitos, view.exerciciosTotal),
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensStrip.s3,
        vertical: TokensStrip.s3,
      ),
      decoration: fxListCardDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, valor) in itens)
            Expanded(
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        valor,
                        maxLines: 1,
                        style: FocuxHubTypography.metric(
                          color: chrome.ink,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cabeçalho da seção seguido das linhas.
class HistoricoSecao extends StatelessWidget {
  const HistoricoSecao({super.key, required this.titulo, required this.filhos});

  final String titulo;
  final List<Widget> filhos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(title: titulo),
        const SizedBox(height: TokensStrip.s2),
        ...filhos,
      ],
    );
  }
}

/// Linhas num grupo único, com divisor entre elas.
class HistoricoGrupo extends StatelessWidget {
  const HistoricoGrupo({super.key, required this.filhos});

  final List<Widget> filhos;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, filho) in filhos.indexed) ...[
            if (i > 0) const Divider(height: 1),
            filho,
          ],
        ],
      ),
    );
  }
}

/// Exercício: fechado mostra a melhor série; aberto, cada série e a orientação.
class HistoricoExercicioTile extends StatefulWidget {
  const HistoricoExercicioTile({super.key, required this.linha});

  final HistoricoExercicioLinha linha;

  @override
  State<HistoricoExercicioTile> createState() => _HistoricoExercicioTileState();
}

class _HistoricoExercicioTileState extends State<HistoricoExercicioTile> {
  var _aberto = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final linha = widget.linha;
    final temDetalhe = linha.series.isNotEmpty || linha.orientacao != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: temDetalhe,
          expanded: temDetalhe ? _aberto : null,
          label: '${linha.nome}. ${historicoExercicioDetalhe(s, linha)}',
          hint: !temDetalhe
              ? null
              : _aberto
              ? s.historicoFecharExercicio
              : s.historicoAbrirExercicio,
          excludeSemantics: true,
          child: InkWell(
            onTap: temDetalhe ? () => setState(() => _aberto = !_aberto) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.all(TokensStrip.s3),
                child: Row(
                  children: [
                    FxIcon(
                      name: linha.feito ? 'circle-check' : 'target',
                      size: 18,
                      color: linha.feito ? EagleTokens.good : chrome.mute,
                    ),
                    const SizedBox(width: TokensStrip.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            linha.nome,
                            style: FocuxHubTypography.cardTitle(color: chrome.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            historicoExercicioDetalhe(s, linha),
                            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                          ),
                        ],
                      ),
                    ),
                    if (temDetalhe)
                      Icon(
                        _aberto
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: chrome.mute,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_aberto)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s3 + 18 + TokensStrip.s3,
              0,
              TokensStrip.s3,
              TokensStrip.s3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final serie in linha.series)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TokensStrip.s1),
                    child: Text(
                      [
                        s.historicoSerieLinha(
                          serie.numero,
                          historicoSerieTexto(s, serie),
                        ),
                        if (serie.rpe case final rpe?) s.historicoRpe(rpe),
                        if (serie.dor) s.historicoDor,
                      ].join(' · '),
                      style: FocuxHubTypography.body(color: chrome.ink),
                    ),
                  ),
                if (linha.orientacao case final texto?) ...[
                  const SizedBox(height: TokensStrip.s1),
                  HistoricoOrientacao(texto: texto),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Fala do personal, com rótulo: nunca parece anotação do aluno.
class HistoricoOrientacao extends StatelessWidget {
  const HistoricoOrientacao({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).historicoOrientacao,
          style: FocuxHubTypography.bodyMuted(
            color: chrome.mute,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(texto, style: FocuxHubTypography.body(color: chrome.ink)),
      ],
    );
  }
}

class HistoricoInfoTile extends StatelessWidget {
  const HistoricoInfoTile({
    super.key,
    required this.titulo,
    required this.detalhe,
    required this.icone,
  });

  final String titulo;
  final String detalhe;
  final String icone;

  @override
  Widget build(BuildContext context) => FxSatelliteListTile(
    title: titulo,
    margin: const EdgeInsets.only(bottom: 2),
    subtitle: Text(detalhe),
    leading: FxIcon(name: icone, size: 20, color: EagleTokens.good),
  );
}
