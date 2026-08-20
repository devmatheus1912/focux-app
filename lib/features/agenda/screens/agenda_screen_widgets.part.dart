part of 'agenda_screen.dart';

class _AgendaEventSheet extends StatefulWidget {
  const _AgendaEventSheet({
    required this.agendamento,
    required this.statusLabel,
    this.photoUrl,
    this.onOpenAluno,
    this.onWhatsapp,
    this.onConfirm,
    this.onComplete,
    this.onCancel,
    required this.onDelete,
  });

  final Agendamento agendamento;
  final String statusLabel;
  final String? photoUrl;
  final Future<void> Function()? onOpenAluno;
  final Future<void> Function()? onWhatsapp;
  final Future<void> Function()? onConfirm;
  final Future<void> Function()? onComplete;
  final Future<void> Function()? onCancel;
  final Future<void> Function() onDelete;

  @override
  State<_AgendaEventSheet> createState() => _AgendaEventSheetState();
}

class _AgendaEventSheetState extends State<_AgendaEventSheet> {
  bool _busy = false;

  Future<void> _run(Future<void> Function()? action) async {
    if (action == null || _busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final ag = widget.agendamento;
    final title = agendaEventTitle(alunoNome: ag.alunoNome, titulo: ag.titulo);
    final note = agendaEventNote(ag.titulo);
    final time =
        ag.fim.isAfter(ag.inicio)
            ? '${agendaHm(ag.inicio)}–${agendaHm(ag.fim)}'
            : agendaHm(ag.inicio);
    final date =
        '${ag.inicio.day.toString().padLeft(2, '0')}/${ag.inicio.month.toString().padLeft(2, '0')}/${ag.inicio.year}';
    final completePrimary = agendaSessionIsDue(ag) && widget.onComplete != null;
    final obs = ag.observacoes?.trim();
    final pos = ag.observacoesPosAtendimento?.trim();
    final atendimento = ag.statusAtendimento?.trim();

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Detalhes do atendimento, $title',
      child: FxHomeSheetSurface(
        isDark: chrome.isDark,
        expand: true,
        maxHeight:
            MediaQuery.sizeOf(context).height *
            FxHomeSheetChrome.expandHeightFactor * 0.9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxHomeSheetHandle(isDark: chrome.isDark),
            SizedBox(height: TokensStrip.s4),
            FxHomeSheetHeader(
              isDark: chrome.isDark,
              title: title,
              subtitle: note,
              leading: FittedBox(
                child: AlunoAvatar(
                  name: title,
                  photoUrl: widget.photoUrl,
                  variant: AlunoAvatarVariant.strip,
                ),
              ),
            ),
            SizedBox(height: TokensStrip.s3),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _AgendaInfoTile(label: 'Data', value: date),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AgendaInfoTile(label: 'Horário', value: time),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _AgendaInfoTile(label: 'Status', value: widget.statusLabel),
                  if (atendimento != null && atendimento.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _AgendaInfoTile(
                      label: 'Após a sessão',
                      value: agendaStatusLabel(atendimento),
                    ),
                  ],
                  if (obs != null && obs.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _AgendaInfoTile(label: 'Nota', value: obs),
                  ],
                  if (pos != null && pos.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _AgendaInfoTile(label: 'Depois do atendimento', value: pos),
                  ],
                ],
              ),
            ),
            SizedBox(height: TokensStrip.s3),
            Semantics(
              button: true,
              label:
                  completePrimary
                      ? 'Marcar atendimento como concluído'
                      : 'Abrir ficha do aluno',
              child: FxLiquidPrimaryButton(
                label:
                    completePrimary ? 'Marcar concluído' : 'Abrir aluno',
                loading: _busy,
                onPressed:
                    _busy
                        ? null
                        : () =>
                            _run(
                              completePrimary
                                  ? widget.onComplete
                                  : widget.onOpenAluno,
                            ),
              ),
            ),
            if (!completePrimary && widget.onComplete != null) ...[
              const SizedBox(height: 8),
              Semantics(
                button: true,
                label: 'Marcar atendimento como concluído',
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _run(widget.onComplete),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Marcar concluído'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (widget.onWhatsapp != null || widget.onConfirm != null)
              Row(
                children: [
                if (widget.onWhatsapp != null)
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'WhatsApp para confirmar horário',
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : () => _run(widget.onWhatsapp),
                        icon: const Icon(Icons.chat_outlined, size: 18),
                        label: const Text('WhatsApp'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: chrome.ink,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (widget.onWhatsapp != null && widget.onConfirm != null)
                  const SizedBox(width: 8),
                if (widget.onConfirm != null)
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Marcar horário como confirmado',
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => _run(widget.onConfirm),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Confirmado'),
                      ),
                    ),
                  ),
              ],
            ),
            if (widget.onCancel != null) ...[
              const SizedBox(height: 4),
              Semantics(
                button: true,
                label: 'Cancelar horário',
                child: TextButton(
                  onPressed: _busy ? null : () => _run(widget.onCancel),
                  child: Text(
                    'Cancelar horário',
                    style: TextStyle(color: chrome.mute),
                  ),
                ),
              ),
            ],
            Semantics(
              button: true,
              label: 'Excluir agendamento',
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _run(widget.onDelete),
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
            maxLines: 3,
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
