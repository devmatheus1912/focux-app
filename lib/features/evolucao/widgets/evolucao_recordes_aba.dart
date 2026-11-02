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

/// Aba Recordes, igual para personal e aluno.
class EvolucaoRecordesAba extends StatelessWidget {
  const EvolucaoRecordesAba({
    super.key,
    required this.recordes,
    required this.vazioSubtitulo,
    required this.onAtualizar,
    this.onEditar,
    this.onExcluir,
  });

  final List<RecordePessoal> recordes;
  final String vazioSubtitulo;
  final Future<void> Function() onAtualizar;

  /// Só para o personal.
  final ValueChanged<RecordePessoal>? onEditar;
  final ValueChanged<RecordePessoal>? onExcluir;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final progresso = progressoDosRecordes(recordes);
    final destaque = maiorProgresso(progresso);
    if (progresso.isEmpty) {
      return RefreshIndicator(
        onRefresh: onAtualizar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            FxEmptyState(
              key: const ValueKey('evolucao_recordes_empty'),
              icon: 'star',
              title: ptS.evolucaoSemRecordeTitulo,
              subtitle: vazioSubtitulo,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onAtualizar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          96,
        ),
        children: [
          if (destaque != null) ...[
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
          for (final p in progresso) ...[
            _CartaoRecorde(progresso: p, onEditar: onEditar, onExcluir: onExcluir),
            const SizedBox(height: TokensStrip.s2),
          ],
        ],
      ),
    );
  }
}

class _CartaoRecorde extends StatelessWidget {
  const _CartaoRecorde({required this.progresso, this.onEditar, this.onExcluir});

  final ProgressoRecorde progresso;
  final ValueChanged<RecordePessoal>? onEditar;
  final ValueChanged<RecordePessoal>? onExcluir;

  Future<void> _acoes(BuildContext context, RecordePessoal r) async {
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: progresso.nome,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'editar',
            rotulo: ptS.evolucaoRecordeEditar,
            icone: Icons.edit_outlined,
          ),
          FxActionItem(
            valor: 'excluir',
            rotulo: ptS.evolucaoRecordeExcluir,
            icone: Icons.delete_outline_rounded,
            perigo: true,
          ),
        ]),
      ],
    );
    if (!context.mounted || escolha == null) return;
    Navigator.pop(context);
    if (escolha == 'editar') {
      onEditar?.call(r);
    } else {
      onExcluir?.call(r);
    }
  }

  void _abrirHistorico(BuildContext context) {
    final emOrdem = progresso.historico.reversed.toList();
    final pontos = [
      for (final r in emOrdem)
        if (r.cargaKg != null && DateTime.tryParse(r.data) != null)
          PontoGrafico(DateTime.parse(r.data), r.cargaKg!),
    ];
    showFxHomeSheet<void>(
      context,
      builder:
          (ctx) => FxSheetFrame(
            title: progresso.nome,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (pontos.length >= evolucaoPontosParaGrafico) ...[
                  FxGraficoLinha(
                    pontos: pontos,
                    unidade: 'kg',
                    altura: 160,
                    resumo: progresso.nome,
                  ),
                  const SizedBox(height: TokensStrip.s3),
                ],
                for (final r in progresso.historico)
                  FxSatelliteListTile(
                    title: evolucaoRecordeSubtitle(r),
                    titleCase: false,
                    trailing:
                        onEditar == null
                            ? const SizedBox.shrink()
                            : const Icon(Icons.more_horiz_rounded),
                    onTap: onEditar == null ? null : () => _acoes(ctx, r),
                  ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final melhor = progresso.melhor;
    final estimado = umRmEstimado(melhor);
    final detalhe = [
      evolucaoRecordeSubtitle(melhor),
      if (estimado != null) ptS.evolucaoRmEstimado(formatBrKg(estimado)),
    ].join(' · ');
    return Semantics(
      button: true,
      label: '${progresso.nome}, $detalhe',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        onTap: () => _abrirHistorico(context),
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
                      progresso.nome,
                      style: FocuxHubTypography.cardTitle(color: chrome.ink),
                    ),
                  ),
                  if (recordeNovo(melhor))
                    FxStatusPill(label: ptS.evolucaoRecordeNovo),
                ],
              ),
              const SizedBox(height: TokensStrip.s1),
              Text(
                detalhe,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
              if (progresso.historico.length > 1) ...[
                const SizedBox(height: TokensStrip.s2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(TokensStrip.s1),
                  child: LinearProgressIndicator(
                    value: progresso.fracaoDoInicio,
                    minHeight: 6,
                    color: primary,
                    backgroundColor: chrome.line,
                  ),
                ),
                const SizedBox(height: TokensStrip.s1),
                Text(
                  ptS.evolucaoGanhoDesdeInicio(
                    diferencaTexto(progresso.ganhoKg, 'kg'),
                  ),
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
