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
    this.onReschedule,
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
  final Future<void> Function()? onReschedule;
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
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Não foi possível concluir.'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmComplete({required String confirmLabel}) async {
    final ok = await showFxConfirmSheet(
      context,
      title: agendaCompleteConfirmTitle(),
      message: agendaCompleteConfirmMessage(widget.agendamento.alunoNome),
      confirmLabel: confirmLabel,
    );
    if (!ok || !mounted) return;
    await _run(widget.onComplete);
  }

  Widget _command({required String label, required VoidCallback? onPressed}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(
          DashboardLayout.touchTarget,
          DashboardLayout.touchTarget,
        ),
        alignment: Alignment.centerLeft,
      ),
      child: Text(_busy ? '…' : label),
    );
  }

  Widget _danger({required String label, required VoidCallback? onPressed}) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: EagleTokens.bad,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  List<Widget> _eventActions({required bool completePrimary}) {
    final nav = <FxSettingsTile>[
      if (widget.onOpenAluno != null)
        FxSettingsTile(
          fxIcon: 'users',
          label:
              completePrimary
                  ? 'Ver aluno'
                  : agendaEventPrimaryLabel(completePrimary: false),
          value: '',
          showDivider: false,
          onTap: _busy ? null : () => _run(widget.onOpenAluno),
        ),
    ];
    final commands = <Widget>[
      if (completePrimary)
        _command(
          label: agendaEventPrimaryLabel(completePrimary: true),
          onPressed:
              _busy
                  ? null
                  : () => _confirmComplete(
                    confirmLabel: agendaEventPrimaryLabel(
                      completePrimary: true,
                    ),
                  ),
        ),
      if (widget.onWhatsapp != null)
        _command(
          label: 'WhatsApp',
          onPressed: _busy ? null : () => _run(widget.onWhatsapp),
        ),
      if (widget.onConfirm != null)
        _command(
          label: 'Confirmado',
          onPressed: _busy ? null : () => _run(widget.onConfirm),
        ),
      if (widget.onReschedule != null)
        _command(
          label: 'Remarcar',
          onPressed: _busy ? null : () => _run(widget.onReschedule),
        ),
      if (!completePrimary && widget.onComplete != null)
        _command(
          label: 'Concluído',
          onPressed:
              _busy
                  ? null
                  : () => _confirmComplete(confirmLabel: 'Concluído'),
        ),
    ];
    final dangers = <Widget>[
      if (widget.onCancel != null)
        _danger(
          label: 'Cancelar horário',
          onPressed: _busy ? null : () => _run(widget.onCancel),
        ),
      _danger(
        label: 'Excluir agendamento',
        onPressed: _busy ? null : () => _run(widget.onDelete),
      ),
    ];

    return [
      if (nav.isNotEmpty) FxSettingsGroup(children: nav),
      for (final command in commands) ...[
        const SizedBox(height: FxSettingsLayout.groupGap),
        command,
      ],
      for (final danger in dangers) ...[
        const SizedBox(height: FxSettingsLayout.groupGap),
        danger,
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ag = widget.agendamento;
    final title = agendaEventTitle(alunoNome: ag.alunoNome, titulo: ag.titulo);
    final sessionNote = agendaEventSessionNote(ag.titulo);
    final subtitle = agendaEventSheetSubtitle(
      inicio: ag.inicio,
      fim: ag.fim,
      statusLabel: widget.statusLabel,
    );
    final date =
        '${ag.inicio.day.toString().padLeft(2, '0')}/${ag.inicio.month.toString().padLeft(2, '0')}/${ag.inicio.year}';
    final time =
        ag.fim.isAfter(ag.inicio)
            ? '${agendaHm(ag.inicio)}–${agendaHm(ag.fim)}'
            : agendaHm(ag.inicio);
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
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxHomeSheetHandle(isDark: chrome.isDark),
            SizedBox(height: TokensStrip.s4),
            FxHomeSheetHeader(
              isDark: chrome.isDark,
              title: title,
              subtitle: subtitle,
              leading: AlunoAvatar(
                name: title,
                photoUrl: widget.photoUrl,
                variant: AlunoAvatarVariant.strip,
              ),
            ),
            SizedBox(height: TokensStrip.s3),
            _AgendaMetaStrip(
              date: date,
              time: time,
              status: widget.statusLabel,
            ),
            if (sessionNote != null) ...[
              const SizedBox(height: TokensStrip.s2),
              _AgendaDetailNote(label: 'Tipo de sessão', value: sessionNote),
            ],
            if (atendimento != null && atendimento.isNotEmpty) ...[
              const SizedBox(height: TokensStrip.s2),
              _AgendaDetailNote(
                label: 'Após a sessão',
                value: agendaStatusLabel(atendimento),
              ),
            ],
            if (obs != null && obs.isNotEmpty) ...[
              const SizedBox(height: TokensStrip.s2),
              _AgendaDetailNote(label: 'Nota', value: obs),
            ],
            if (pos != null && pos.isNotEmpty) ...[
              const SizedBox(height: TokensStrip.s2),
              _AgendaDetailNote(label: 'Depois do atendimento', value: pos),
            ],
            SizedBox(height: TokensStrip.s4),
            ..._eventActions(completePrimary: completePrimary),
          ],
        ),
      ),
    );
  }
}

class _AgendaMetaStrip extends StatelessWidget {
  const _AgendaMetaStrip({
    required this.date,
    required this.time,
    required this.status,
  });

  final String date;
  final String time;
  final String status;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: fxStripCardDecoration(
        context,
        accent: primary,
        radius: 16,
        glowStrength: 0.03,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _AgendaMetaCell(label: 'Data', value: date)),
              _AgendaMetaDivider(color: primary),
              Expanded(child: _AgendaMetaCell(label: 'Horário', value: time)),
              _AgendaMetaDivider(color: primary),
              Expanded(child: _AgendaMetaCell(label: 'Status', value: status)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaMetaDivider extends StatelessWidget {
  const _AgendaMetaDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: VerticalDivider(
        width: 1,
        thickness: 1,
        color: color.withValues(alpha: 0.16),
      ),
    );
  }
}

class _AgendaMetaCell extends StatelessWidget {
  const _AgendaMetaCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FocuxHubTypography.chip(chrome.mute),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: FocuxHubTypography.body(color: chrome.ink).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AgendaDetailNote extends StatelessWidget {
  const _AgendaDetailNote({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: fxStripCardDecoration(
        context,
        accent: primary,
        radius: 14,
        glowStrength: 0.02,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: FocuxHubTypography.chip(chrome.mute),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: FocuxHubTypography.bodyMuted(
                color: chrome.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
