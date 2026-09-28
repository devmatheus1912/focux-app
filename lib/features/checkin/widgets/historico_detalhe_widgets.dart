import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/operational_metric_tile.dart';
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

/// Status, duração e a comparação com a sessão anterior.
class HistoricoResumoCard extends StatelessWidget {
  const HistoricoResumoCard({super.key, required this.view});

  final HistoricoDetalheView view;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final duracao = view.duracao;
    final linhas =
        [
          historicoComparacaoTexto(s, view.comparacao),
          historicoDestaqueTexto(s, view),
        ].nonNulls;
    return FxStripCard(
      accent: primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: TokensStrip.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                historicoDetalheStatus(s, view),
                style: FocuxHubTypography.sectionTitle(
                  context,
                  color: chrome.ink,
                ),
              ),
              if (duracao != null)
                Text(
                  treinosDuracaoTexto(s, duracao),
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
            ],
          ),
          for (final linha in linhas) ...[
            const SizedBox(height: TokensStrip.s1),
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

/// Volume (só com carga), séries e exercícios feitos.
class HistoricoMetricas extends StatelessWidget {
  const HistoricoMetricas({super.key, required this.view});

  final HistoricoDetalheView view;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = ShellChrome.of(context).isDark;
    final volume = view.volumeKg;
    Widget tile(String label, String valor) => Expanded(
      child: OperationalMetricTile(
        label: label,
        value: valor,
        color: primary,
        isDark: isDark,
        dense: true,
        emphasis: OperationalMetricEmphasis.muted,
      ),
    );
    final tiles = [
      if (volume != null) tile(s.historicoVolume, historicoKgTexto(s, volume)),
      tile(
        s.historicoSeries,
        historicoNDeMTexto(s, view.seriesFeitas, view.seriesPlanejadas),
      ),
      tile(
        s.historicoExercicios,
        historicoNDeMTexto(s, view.exerciciosFeitos, view.exerciciosTotal),
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, t) in tiles.indexed) ...[
          if (i > 0) const SizedBox(width: TokensStrip.s2),
          t,
        ],
      ],
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

class HistoricoExercicioTile extends StatelessWidget {
  const HistoricoExercicioTile({super.key, required this.linha});

  final HistoricoExercicioLinha linha;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return FxSatelliteListTile(
      title: linha.nome,
      margin: const EdgeInsets.only(bottom: 2),
      subtitle: Text(historicoExercicioDetalhe(s, linha)),
      leading: FxIcon(
        name: linha.feito ? 'circle-check' : 'target',
        size: 18,
        color: linha.feito ? EagleTokens.good : ShellChrome.of(context).mute,
      ),
      trailing:
          linha.cargas.length >= 2
              ? ExcludeSemantics(
                child: FxSparkline(
                  data: linha.cargas,
                  color: primary,
                  width: 44,
                  height: 18,
                  strokeWidth: 1.5,
                ),
              )
              : null,
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
