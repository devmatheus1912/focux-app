import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_empty_state.dart';
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
  });

  final List<RecordePessoal> recordes;
  final String vazioSubtitulo;
  final Future<void> Function() onAtualizar;

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
            _CartaoRecorde(progresso: p),
            const SizedBox(height: TokensStrip.s2),
          ],
        ],
      ),
    );
  }
}

class _CartaoRecorde extends StatelessWidget {
  const _CartaoRecorde({required this.progresso});

  final ProgressoRecorde progresso;

  void _abrirHistorico(BuildContext context) {
    final chrome = ShellChrome.of(context);
    showFxHomeSheet<void>(
      context,
      builder:
          (_) => FxSheetFrame(
            title: progresso.nome,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final r in progresso.historico)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: TokensStrip.s1,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            evolucaoRecordeSubtitle(r),
                            style: FocuxHubTypography.body(color: chrome.ink),
                          ),
                        ),
                      ],
                    ),
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
