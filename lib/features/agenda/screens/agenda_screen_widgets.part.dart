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
      child: FxHomeSheetSurface(
        isDark: chrome.isDark,
        maxHeight:
            MediaQuery.sizeOf(context).height *
            FxHomeSheetChrome.maxHeightFactor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxHomeSheetHandle(isDark: chrome.isDark),
            SizedBox(height: TokensStrip.s4),
            FxHomeSheetHeader(
              isDark: chrome.isDark,
              title: title,
              subtitle: agendamento.alunoNome,
              leading: Icon(
                Icons.event_note_outlined,
                color: primary,
                size: 18,
              ),
            ),
            SizedBox(height: TokensStrip.s3),
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
