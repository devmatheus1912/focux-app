part of 'trilhas_screen.dart';

class _TrilhaCard extends StatelessWidget {
  final TrilhaModel trilha;
  final VoidCallback onAtualizarProgresso;
  final VoidCallback onAdicionarMarco;
  final VoidCallback onDeletar;
  final ValueChanged<MarcoModel> onConcluirMarco;

  const _TrilhaCard({
    required this.trilha,
    required this.onAtualizarProgresso,
    required this.onAdicionarMarco,
    required this.onDeletar,
    required this.onConcluirMarco,
  });

  Color _progressColor(BuildContext context) {
    if (trilha.concluida) return EagleTokens.good;
    if (trilha.percentualConclusao >= 70) {
      return Theme.of(context).colorScheme.primary;
    }
    if (trilha.percentualConclusao >= 30) return EagleTokens.warn;
    return ShellChrome.of(context).mute;
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor = _progressColor(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: fxListCardDecoration(
        context,
        accent: trilha.concluida ? EagleTokens.good : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trilha.titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: chrome.ink,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (trilha.concluida
                            ? EagleTokens.good
                            : primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trilhaStatusLabel(trilha.concluida),
                    style: FocuxHubTypography.chip(
                      trilha.concluida ? EagleTokens.good : primary,
                    ),
                  ),
                ),
              ],
            ),
            if (trilha.descricao != null && trilha.descricao!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                trilha.descricao!,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${trilhaMetaTipoLabel(trilha.metaTipo)} · ${trilhaValorAtualLabel(trilha)}',
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progresso',
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
                Text(
                  trilhaPercentLabel(trilha.percentualConclusao),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: progressColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Semantics(
              label:
                  'Progresso da trilha: ${trilhaPercentLabel(trilha.percentualConclusao)}',
              child: LinearProgressIndicator(
                value: (trilha.percentualConclusao / 100).clamp(0.0, 1.0),
                backgroundColor: progressColor.withValues(alpha: 0.1),
                color: progressColor,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (trilha.marcos.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Marcos',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: chrome.ink,
                ),
              ),
              const SizedBox(height: 6),
              ...trilha.marcos.map(
                (m) => _MarcoTile(
                  marco: m,
                  onConcluir:
                      m.concluido ? null : () => onConcluirMarco(m),
                ),
              ),
            ],
            const SizedBox(height: TokensStrip.s3),
            Wrap(
              spacing: TokensStrip.s2,
              runSpacing: TokensStrip.s2,
              children: [
                if (trilha.metaValor != null && !trilha.concluida)
                  DashboardHomeActionChip(
                    label: 'Atualizar progresso',
                    accent: primary,
                    isDark: isDark,
                    onPressed: onAtualizarProgresso,
                  ),
                DashboardHomeActionChip(
                  label: 'Nova etapa',
                  accent: primary,
                  isDark: isDark,
                  onPressed: onAdicionarMarco,
                ),
                DashboardHomeActionChip(
                  label: 'Excluir',
                  accent: EagleTokens.bad,
                  isDark: isDark,
                  onPressed: onDeletar,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MarcoTile extends StatelessWidget {
  final MarcoModel marco;
  final VoidCallback? onConcluir;

  const _MarcoTile({
    required this.marco,
    required this.onConcluir,
  });

  @override
  Widget build(BuildContext context) {
    return fxListTileCardShell(
      context: context,
      margin: EdgeInsets.zero,
      accent: marco.concluido ? EagleTokens.good : null,
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: IconButton(
          tooltip: marco.concluido ? 'Marco concluído' : 'Concluir marco',
          icon: Icon(
            marco.concluido ? Icons.check_circle : Icons.radio_button_unchecked,
            color:
                marco.concluido
                    ? EagleTokens.good
                    : ShellChrome.of(context).mute,
          ),
          onPressed: onConcluir,
        ),
        title: Text(
          marco.titulo,
          style: TextStyle(
            fontSize: 13,
            decoration: marco.concluido ? TextDecoration.lineThrough : null,
            color: marco.concluido ? TokensStrip.textSecondary : null,
          ),
        ),
        onTap: onConcluir,
      ),
    );
  }
}

class _TrilhasListBody extends StatelessWidget {
  const _TrilhasListBody({
    required this.trilhas,
    required this.freshness,
    required this.alunoNome,
    required this.filtro,
    required this.onFiltro,
    required this.onRefresh,
    required this.onAtualizarProgresso,
    required this.onAdicionarMarco,
    required this.onDeletar,
    required this.onConcluirMarco,
  });

  final List<TrilhaModel> trilhas;
  final String? freshness;
  final String alunoNome;
  final String filtro;
  final ValueChanged<String> onFiltro;
  final Future<void> Function() onRefresh;
  final ValueChanged<TrilhaModel> onAtualizarProgresso;
  final ValueChanged<TrilhaModel> onAdicionarMarco;
  final ValueChanged<TrilhaModel> onDeletar;
  final void Function(TrilhaModel trilha, MarcoModel marco) onConcluirMarco;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final visiveis = trilhaFiltradas(trilhas, filtro);
    final nome = fxTitleCaseName(alunoNome);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s4,
          FxSettingsLayout.pageInset,
          32,
        ),
        children: [
          FxHubHeader(
            title: nome,
            subtitle: trilhaHubSubtitle(
              alunoNome: alunoNome,
              freshness: freshness,
            ),
          ),
          const SizedBox(height: TokensStrip.s4),
          OperationalMetricTile(
            label: 'Ativas',
            value: '${trilhaAtivasCount(trilhas)}',
            hint:
                trilhas.isEmpty
                    ? 'Nenhuma trilha atribuída'
                    : '${trilhaConcluidasCount(trilhas)} concluídas',
            color: primary,
            isDark: isDark,
          ),
          const SizedBox(height: TokensStrip.s2),
          OperationalMetricTile(
            label: 'Progresso',
            value: trilhaProgressoMedioLabel(trilhas),
            hint: 'Média das trilhas deste aluno',
            color: primary,
            isDark: isDark,
          ),
          const SizedBox(height: TokensStrip.s2),
          OperationalMetricTile(
            label: 'Marcos',
            value: '${trilhaMarcosPendentes(trilhas)}',
            hint:
                trilhaMarcosPendentes(trilhas) == 0
                    ? 'Nada pendente'
                    : 'Etapas em aberto',
            color: primary,
            isDark: isDark,
          ),
          if (trilhas.isNotEmpty) ...[
            const SizedBox(height: TokensStrip.s4),
            AlunoSegmentedChoice(
              options: trilhaFiltroOpcoes,
              selected: filtro,
              isDark: isDark,
              onSelect: onFiltro,
            ),
          ],
          const SizedBox(height: TokensStrip.s5),
          if (trilhas.isEmpty)
            const FxEmptyState(
              icon: 'route',
              title: 'Nenhuma trilha atribuída',
              subtitle:
                  'Crie uma meta com etapas para acompanhar o progresso deste aluno.',
            )
          else if (visiveis.isEmpty)
            FxEmptyState(
              icon: 'route',
              title:
                  filtro == trilhaFiltroConcluidas
                      ? 'Nenhuma trilha concluída'
                      : 'Nada em andamento',
              subtitle:
                  filtro == trilhaFiltroConcluidas
                      ? 'As trilhas ativas aparecem na outra seção.'
                      : 'Tudo que existia já foi concluído.',
              action: FxEmptyAction(
                label:
                    filtro == trilhaFiltroConcluidas
                        ? 'Ver em andamento'
                        : 'Ver concluídas',
                onTap:
                    () => onFiltro(
                      filtro == trilhaFiltroConcluidas
                          ? trilhaFiltroAndamento
                          : trilhaFiltroConcluidas,
                    ),
              ),
            )
          else ...[
            const DashboardSectionHeader(title: 'Trilhas'),
            const SizedBox(height: TokensStrip.s3),
            for (final trilha in visiveis)
              _TrilhaCard(
                trilha: trilha,
                onAtualizarProgresso: () => onAtualizarProgresso(trilha),
                onAdicionarMarco: () => onAdicionarMarco(trilha),
                onDeletar: () => onDeletar(trilha),
                onConcluirMarco: (marco) => onConcluirMarco(trilha, marco),
              ),
          ],
        ],
      ),
    );
  }
}
