part of 'agenda_screen.dart';

class _AgendaEventSheet extends StatelessWidget {
  final Agendamento agendamento;
  final String statusLabel;
  final Future<void> Function() onDelete;

  const _AgendaEventSheet({
    required this.agendamento,
    required this.statusLabel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final title = _displayTitle(agendamento.titulo ?? 'Atendimento');
    final time =
        agendamento.fim.isAfter(agendamento.inicio)
            ? '${_hm(agendamento.inicio)}–${_hm(agendamento.fim)}'
            : _hm(agendamento.inicio);
    final date =
        '${agendamento.inicio.day.toString().padLeft(2, '0')}/${agendamento.inicio.month.toString().padLeft(2, '0')}/${agendamento.inicio.year}';

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Detalhes do atendimento, $title, ${agendamento.alunoNome}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 10, 20, 20),
        decoration: _agendaSheetDecoration(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _agendaSheetHandle(context),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: primary.withValues(
                      alpha: chrome.isDark ? 0.22 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.event_note_outlined,
                    size: 20,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: chrome.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        agendamento.alunoNome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 12,
                          color: chrome.mute,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Fechar detalhes do atendimento',
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: chrome.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _AgendaInfoTile(label: 'Data', value: date)),
                const SizedBox(width: 10),
                Expanded(child: _AgendaInfoTile(label: 'Horário', value: time)),
              ],
            ),
            const SizedBox(height: 10),
            _AgendaInfoTile(label: 'Status', value: statusLabel),
            const SizedBox(height: TokensStrip.s4),
            Semantics(
              button: true,
              label: 'Excluir agendamento',
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Excluir agendamento'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EagleTokens.bad,
                  side: const BorderSide(color: EagleTokens.badSoft),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hm(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String _displayTitle(String value) {
    if (value.trim().toLowerCase() == 'avaliacao') return 'Avaliação';
    return value;
  }
}

class _AgendaInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _AgendaInfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: chrome.isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: chrome.mute,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: chrome.ink,
            ),
          ),
        ],
      ),
    );
  }
}
