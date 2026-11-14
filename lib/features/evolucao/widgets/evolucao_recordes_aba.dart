import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_grafico_linha.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../l10n/pt.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_display.dart';
import '../utils/evolucao_series.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/widgets/fx_link_row.dart';

/// Aba Força, igual para personal e aluno, no mesmo padrão do Corpo: o gráfico
/// do exercício escolhido no topo, a lista embaixo (tocar escolhe) e "Ver
/// registros" (editar e excluir ficam lá, só para o personal).
class EvolucaoRecordesAba extends StatefulWidget {
  const EvolucaoRecordesAba({
    super.key,
    required this.recordes,
    required this.vazioSubtitulo,
    required this.onAtualizar,
    this.onEditar,
    this.onExcluir,
    this.depois = const [],
  });

  final List<RecordePessoal> recordes;
  final String vazioSubtitulo;
  final Future<void> Function() onAtualizar;

  /// Só para o personal.
  final ValueChanged<RecordePessoal>? onEditar;
  final ValueChanged<RecordePessoal>? onExcluir;

  /// Conquistas de força, depois da lista.
  final List<Widget> depois;

  @override
  State<EvolucaoRecordesAba> createState() => _EvolucaoRecordesAbaState();
}

class _EvolucaoRecordesAbaState extends State<EvolucaoRecordesAba> {
  String? _escolhido;

  static String _chave(String nome) => nome.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final progresso = progressoDosRecordes(widget.recordes);
    final destaque = maiorProgresso(progresso);
    if (progresso.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onAtualizar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            FxEmptyState(
              key: const ValueKey('evolucao_recordes_empty'),
              icon: FxIcons.estrela,
              title: ptS.evolucaoSemRecordeTitulo,
              subtitle: widget.vazioSubtitulo,
            ),
          ],
        ),
      );
    }
    final escolhido =
        progresso.where((p) => _chave(p.nome) == _escolhido).firstOrNull ??
        progresso.first;
    return RefreshIndicator(
      onRefresh: widget.onAtualizar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          96,
        ),
        children: [
          // Com um exercício só, o destaque repetia a lista.
          if (destaque != null && progresso.length > 1) ...[
            Text(
              ptS.evolucaoMaiorProgresso,
              style: FocuxHubTypography.chip(chrome.mute),
            ),
            const SizedBox(height: 2),
            Text(
              ptS.evolucaoProgressoFrase(
                destaque.nome,
                diferencaTexto(destaque.ganhoKg, 'kg'),
              ),
              style: FocuxHubTypography.cardTitle(color: chrome.ink),
            ),
            const SizedBox(height: TokensStrip.s3),
          ],
          _BlocoDoExercicio(
            progresso: escolhido,
            onVerRegistros:
                () => abrirRegistrosDoExercicio(
                  context,
                  escolhido,
                  onEditar: widget.onEditar,
                  onExcluir: widget.onExcluir,
                ),
          ),
          const SizedBox(height: TokensStrip.s3),
          Container(
            decoration: fxListCardDecoration(context),
            child: Column(
              children: [
                for (final (i, p) in progresso.indexed) ...[
                  if (i > 0) Divider(height: 1, color: chrome.line),
                  _LinhaDoExercicio(
                    progresso: p,
                    selecionada: identical(p, escolhido),
                    onTap: () => setState(() => _escolhido = _chave(p.nome)),
                  ),
                ],
              ],
            ),
          ),
          // Um dia por exercício ainda não tem evolução: diz o que falta.
          if (progresso.every((p) => diasDistintos(p.historico) < 2))
            Padding(
              padding: const EdgeInsets.only(top: TokensStrip.s2),
              child: Text(
                ptS.evolucaoForcaProximo,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ),
          const SizedBox(height: TokensStrip.s4),
          ...widget.depois,
        ],
      ),
    );
  }
}

/// Dias diferentes com registro: dois no mesmo dia não são evolução.
int diasDistintos(List<RecordePessoal> historico) =>
    {for (final r in historico) r.data.length >= 10 ? r.data.substring(0, 10) : r.data}
        .length;

/// Série do exercício: a maior carga de cada dia, do mais antigo ao mais novo.
List<PontoGrafico> serieDoExercicio(ProgressoRecorde p) => umPorDia([
  for (final r in p.historico.reversed)
    if (r.cargaKg != null && DateTime.tryParse(r.data) != null)
      PontoGrafico(DateTime.parse(r.data), r.cargaKg!),
], maior: true);

class _BlocoDoExercicio extends StatelessWidget {
  const _BlocoDoExercicio({required this.progresso, required this.onVerRegistros});

  final ProgressoRecorde progresso;
  final VoidCallback onVerRegistros;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final pontos = serieDoExercicio(progresso);
    final melhor = progresso.melhor;
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  progresso.nome,
                  style: FocuxHubTypography.cardTitle(color: chrome.ink),
                ),
              ),
              if (melhor.cargaKg case final kg?)
                Text(
                  formatBrComUnidade(kg, 'kg'),
                  style: FocuxHubTypography.cardTitle(color: chrome.ink)
                      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
            ],
          ),
          const SizedBox(height: TokensStrip.s3),
          if (pontos.length >= evolucaoPontosParaGrafico)
            RepaintBoundary(
              child: FxGraficoLinha(
                pontos: pontos,
                unidade: 'kg',
                altura: 160,
                resumo: progresso.nome,
              ),
            )
          else if (DateTime.tryParse(melhor.data) case final data?)
            // Um dia só não é série: valor e data, sem gráfico.
            Text(
              ptS.evolucaoRegistradoEm(dataCurta(data)),
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          const SizedBox(height: TokensStrip.s2),
          FxLinkRow(
            label: ptS.evolucaoVerRegistros,
            icon: FxIcons.historico,
            onTap: onVerRegistros,
          ),
        ],
      ),
    );
  }
}

/// Uma linha por exercício: melhor marca e, com 2 dias ou mais, o ganho.
class _LinhaDoExercicio extends StatelessWidget {
  const _LinhaDoExercicio({
    required this.progresso,
    required this.selecionada,
    required this.onTap,
  });

  final ProgressoRecorde progresso;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final melhor = progresso.melhor;
    final estimado = umRmEstimado(melhor);
    final marca = [
      evolucaoRecordeSubtitle(melhor),
      if (estimado != null) ptS.evolucaoRmEstimado(formatBrComUnidade(estimado, 'kg')),
    ].join(' · ');
    final evoluiu = diasDistintos(progresso.historico) >= 2;
    final ganho =
        evoluiu
            ? ptS.evolucaoGanhoDesdeInicio(diferencaTexto(progresso.ganhoKg, 'kg'))
            : null;
    return Semantics(
      button: true,
      selected: selecionada,
      label: [
        progresso.nome,
        ptS.evolucaoMelhorMarca(marca),
        if (ganho != null) ganho,
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(TokensStrip.s3),
          color: selecionada ? primary.withValues(alpha: 0.07) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                progresso.nome,
                style: FocuxHubTypography.cardTitle(
                  color: selecionada ? primary : chrome.ink,
                ),
              ),
              Text(
                ptS.evolucaoMelhorMarca(marca),
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
              if (ganho != null)
                Text(
                  ganho,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Registros do exercício em lista agrupada, o melhor com a etiqueta
/// "Recorde". Editar e excluir no "⋯" (só o personal).
Future<void> abrirRegistrosDoExercicio(
  BuildContext context,
  ProgressoRecorde progresso, {
  ValueChanged<RecordePessoal>? onEditar,
  ValueChanged<RecordePessoal>? onExcluir,
}) {
  Future<void> acoes(BuildContext ctx, RecordePessoal r) async {
    final escolha = await showFxGroupedActionSheet<String>(
      ctx,
      titulo: progresso.nome,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'editar',
            rotulo: ptS.evolucaoRecordeEditar,
            icone: FxIcons.editar,
          ),
          FxActionItem(
            valor: 'excluir',
            rotulo: ptS.evolucaoRecordeExcluir,
            icone: FxIcons.excluir,
            perigo: true,
          ),
        ]),
      ],
    );
    if (!ctx.mounted || escolha == null) return;
    Navigator.pop(ctx);
    if (escolha == 'editar') {
      onEditar?.call(r);
    } else {
      onExcluir?.call(r);
    }
  }

  return showFxHomeSheet<void>(
    context,
    builder: (ctx) {
      final chrome = ShellChrome.of(ctx);
      return FxSheetFrame(
        title: progresso.nome,
        child: Container(
          decoration: fxListCardDecoration(ctx),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, r) in progresso.historico.indexed) ...[
                if (i > 0) Divider(height: 1, color: chrome.line),
                FxSatelliteListTile(
                  title: evolucaoRecordeSubtitle(r),
                  titleCase: false,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (identical(r, progresso.melhor))
                        FxStatusPill(label: ptS.evolucaoRecordeEtiqueta),
                      if (onEditar != null) ...[
                        const SizedBox(width: TokensStrip.s2),
                        Icon(FxIcons.mais, color: chrome.mute),
                      ],
                    ],
                  ),
                  onTap: onEditar == null ? null : () => acoes(ctx, r),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
