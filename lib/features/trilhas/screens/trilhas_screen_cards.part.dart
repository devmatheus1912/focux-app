part of 'trilhas_screen.dart';

class _TrilhaCard extends StatelessWidget {
  final TrilhaModel trilha;
  final VoidCallback onAtualizarProgresso;
  final VoidCallback onDeletar;
  final ValueChanged<MarcoModel> onConcluirMarco;

  const _TrilhaCard({
    required this.trilha,
    required this.onAtualizarProgresso,
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
