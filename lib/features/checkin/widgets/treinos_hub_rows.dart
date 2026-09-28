import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../treinos/utils/treino_atribuicao_prazo.dart';
import '../../treinos/widgets/treino_prazo_badge.dart';
import '../data/checkin_repository.dart';
import '../utils/treino_ficha_status.dart';
import '../utils/treinos_hub_texts.dart';
import '../utils/treinos_hub_view.dart';

/// Seção do hub: título + cartão de lista. Sem linhas, nada.
class TreinosHubSecao extends StatelessWidget {
  const TreinosHubSecao({
    super.key,
    required this.titulo,
    required this.linhas,
    this.acaoLabel,
    this.onAcao,
  });

  final String titulo;
  final List<Widget> linhas;
  final String? acaoLabel;
  final VoidCallback? onAcao;

  @override
  Widget build(BuildContext context) {
    if (linhas.isEmpty) return const SizedBox.shrink();
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(
          title: titulo,
          actionLabel: acaoLabel,
          onAction: onAcao,
        ),
        const SizedBox(height: TokensStrip.s2),
        Container(
          padding: const EdgeInsets.symmetric(vertical: TokensStrip.s1),
          decoration: fxListCardDecoration(context, accent: primary),
          child: Column(children: linhas),
        ),
      ],
    );
  }
}

/// Ficha do plano: toque abre a prévia (ou o status, em preparação).
class TreinoPlanoRow extends StatelessWidget {
  const TreinoPlanoRow({
    super.key,
    required this.treino,
    required this.hoje,
    required this.onTap,
  });

  final ExecucaoTreino treino;
  final DateTime hoje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final detalhe = treinosPlanoDetalhe(s, treino);
    final prazo = TreinoAtribuicaoPrazo.parseIsoDate(treino.dataFim);
    final prazoLabel = TreinoAtribuicaoPrazo.chipLabel(prazo, today: hoje);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _HubRow(
      semanticsLabel: [
        treino.treinoNome,
        detalhe,
        if (prazoLabel != null) prazoLabel,
      ].join(', '),
      onTap: onTap,
      icone:
          isTreinoAguardandoLiberacao(treino)
              ? Icons.pending_actions_rounded
              : Icons.fitness_center_rounded,
      titulo: treino.treinoNome,
      detalhe: detalhe,
      extra:
          prazoLabel == null
              ? null
              : TreinoPrazoBadge(dataFim: prazo, isDark: isDark, today: hoje),
      trailing: const _Seta(),
    );
  }
}

/// Próximo do rodízio depois do treino de hoje: linha compacta com "Iniciar".
class TreinoDepoisRow extends StatelessWidget {
  const TreinoDepoisRow({
    super.key,
    required this.treino,
    required this.onTap,
    required this.onIniciar,
  });

  final ExecucaoTreino treino;
  final VoidCallback onTap;
  final VoidCallback onIniciar;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final detalhe = treinosPlanoDetalhe(s, treino);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _HubRow(
      semanticsLabel: '${treino.treinoNome}, $detalhe',
      onTap: onTap,
      icone: Icons.fitness_center_rounded,
      titulo: treino.treinoNome,
      detalhe: detalhe,
      trailing: FxActionChip(
        label: s.treinosIniciarCurto,
        accent: primary,
        isDark: isDark,
        onPressed: onIniciar,
      ),
    );
  }
}

/// Execução concluída: "Hoje · 52 min". Toque abre o detalhe.
class TreinoRecenteRow extends StatelessWidget {
  const TreinoRecenteRow({
    super.key,
    required this.recente,
    required this.hoje,
    required this.onTap,
  });

  final TreinoRecente recente;
  final DateTime hoje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final dia = treinosDiaTexto(s, recente.quando, hoje: hoje);
    final detalhe = treinosRecenteDetalhe(s, recente);
    final nome = recente.execucao.treinoNome;
    return _HubRow(
      semanticsLabel: '$dia, $nome, $detalhe',
      onTap: onTap,
      icone: Icons.check_rounded,
      corIcone: EagleTokens.good,
      titulo: nome,
      detalhe: '$dia · $detalhe',
      trailing: const _Seta(),
    );
  }
}

class _HubRow extends StatelessWidget {
  const _HubRow({
    required this.semanticsLabel,
    required this.onTap,
    required this.icone,
    required this.titulo,
    required this.detalhe,
    required this.trailing,
    this.corIcone,
    this.extra,
  });

  final String semanticsLabel;
  final VoidCallback onTap;
  final IconData icone;
  final Color? corIcone;
  final String titulo;
  final String detalhe;
  final Widget? extra;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cor = corIcone ?? primary;

    return InkWell(
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
              Expanded(
                child: Semantics(
                  button: true,
                  label: semanticsLabel,
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: BrandPalette.soft(cor, dark: isDark),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icone, size: 18, color: cor),
                      ),
                      const SizedBox(width: TokensStrip.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              titulo,
                              style: FocuxHubTypography.cardTitle(
                                color: chrome.ink,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              detalhe,
                              style: FocuxHubTypography.bodyMuted(
                                color: chrome.mute,
                              ),
                            ),
                            if (extra case final e?) ...[
                              const SizedBox(height: TokensStrip.s1),
                              e,
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: TokensStrip.s2),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _Seta extends StatelessWidget {
  const _Seta();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Icon(
      Icons.chevron_right_rounded,
      size: 20,
      color: ShellChrome.of(context).mute,
    ),
  );
}
