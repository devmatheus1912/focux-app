part of 'trilhas_screen.dart';

class _TrilhaCard extends StatelessWidget {
  final TrilhaModel trilha;
  final int alunoId;
  final WidgetRef ref;

  const _TrilhaCard({
    required this.trilha,
    required this.alunoId,
    required this.ref,
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
                if (trilha.concluida)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: EagleTokens.good.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trilhaStatusLabel(true),
                      style: FocuxHubTypography.chip(EagleTokens.good),
                    ),
                  ),
              ],
            ),
            if (trilha.descricao != null) ...[
              const SizedBox(height: 4),
              Text(
                trilha.descricao!,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ],
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
                  trilhaId: trilha.id,
                  alunoId: alunoId,
                  ref: ref,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MarcoTile extends StatelessWidget {
  final MarcoModel marco;
  final int trilhaId;
  final int alunoId;
  final WidgetRef ref;

  const _MarcoTile({
    required this.marco,
    required this.trilhaId,
    required this.alunoId,
    required this.ref,
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
          onPressed:
              marco.concluido
                  ? null
                  : () async {
                    await ref
                        .read(trilhasRepositoryProvider)
                        .concluirMarco(trilhaId: trilhaId, marcoId: marco.id);
                    ref.invalidate(trilhasAlunoProvider(alunoId));
                  },
        ),
        title: Text(
          marco.titulo,
          style: TextStyle(
            fontSize: 13,
            decoration: marco.concluido ? TextDecoration.lineThrough : null,
            color: marco.concluido ? TokensStrip.textSecondary : null,
          ),
        ),
      ),
    );
  }
}
