part of 'agenda_screen.dart';

extension on _AgendaScreenState {
  Future<bool> _confirmDestructive({
    required String title,
    required String body,
    required String confirmLabel,
  }) {
    return showFxConfirmSheet(
      context,
      title: title,
      message: body,
      confirmLabel: confirmLabel,
      cancelLabel: 'Voltar',
      destructive: true,
    );
  }

  Future<void> _setStatus(Agendamento ag, String status) async {
    await ref.read(agendaRepositoryProvider).atualizarStatus(ag.id, status);
    if (!mounted) return;
    Navigator.pop(context);
    await _load(force: true);
    if (!mounted) return;
    AnalyticsService.instance.track(
      ProductEvents.agendaStatusChanged,
      props: {'status': status},
    );
    FeedbackHelper.showSuccess(
      context,
      status == 'CONFIRMADO'
          ? 'Horário confirmado.'
          : status == 'CONCLUIDO'
          ? 'Atendimento concluído.'
          : 'Horário cancelado.',
    );
  }

  Future<void> _reschedule(Agendamento ag) async {
    final dt = await showFxHomeSheet<DateTime>(
      context,
      builder:
          (_) => AgendaDateTimeSheet(
            title: 'Novo início',
            initial: ag.inicio,
          ),
    );
    if (dt == null || !mounted) return;
    final fim = dt.add(ag.fim.difference(ag.inicio));
    await ref
        .read(agendaRepositoryProvider)
        .atualizarHorario(ag.id, dt, fim, titulo: ag.titulo);
    if (!mounted) return;
    Navigator.pop(context);
    await _load(force: true);
    if (!mounted) return;
    AnalyticsService.instance.track(ProductEvents.agendaRescheduled);
    FeedbackHelper.showSuccess(context, 'Horário remarcado.');
  }

  /// Combina `Env.apiUrl` (https://host[/api]) com um path relativo (/api/...) sem
  /// duplicar segmentos. Aceita também URL já absoluta vinda do backend.
  String _resolveAbsoluteApiUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    var base = Env.apiUrl;
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    final path = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
    if (base.endsWith('/api') && path.startsWith('/api/')) {
      base = base.substring(0, base.length - 4);
    }
    return '$base$path';
  }

  Future<void> _copyIcalLink() async {
    try {
      final info = await ref.read(agendaRepositoryProvider).icalToken();
      final fullUrl = _resolveAbsoluteApiUrl(info.url);
      await copySensitiveToClipboard(fullUrl);
      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          'Link iCal copiado — cole no Google Calendar ou Apple Calendar.',
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Erro ao gerar link iCal.'),
        );
      }
    }
  }

  Future<void> _openAgendamentoDetails(Agendamento ag) async {
    Aluno? aluno = _alunoFromCache(ag.alunoId);
    try {
      aluno = await ref.read(alunoProvider(ag.alunoId).future);
    } catch (_) {}
    if (!mounted) return;
    final digits = (aluno?.whatsapp ?? '').replaceAll(RegExp(r'\D'), '');
    final actionable = agendaStatusIsActionable(ag.status);

    await showFxHomeSheet<void>(
      context,
      builder:
          (_) => _AgendaEventSheet(
            agendamento: ag,
            statusLabel: agendaStatusLabel(ag.status),
            photoUrl: aluno?.fotoUrl ?? _photoFor(ag.alunoId),
            onOpenAluno: () async {
              Navigator.pop(context);
              if (!mounted) return;
              AnalyticsService.instance.track(ProductEvents.agendaAlunoOpened);
              context.push('/alunos/${ag.alunoId}');
            },
            onWhatsapp:
                digits.isEmpty
                    ? null
                    : () {
                      AnalyticsService.instance.track(
                        ProductEvents.agendaWhatsapp,
                      );
                      return openAlunoWhatsappOutreach(
                        context,
                        displayName: ag.alunoNome,
                        whatsappNumber: digits,
                        emRisco: aluno?.emRisco ?? false,
                        message: agendaWhatsappReminder(
                          alunoNome: ag.alunoNome,
                          inicio: ag.inicio,
                        ),
                      );
                    },
            onConfirm:
                agendaStatusNeedsConfirm(ag.status)
                    ? () => _setStatus(ag, 'CONFIRMADO')
                    : null,
            onComplete:
                actionable ? () => _setStatus(ag, 'CONCLUIDO') : null,
            onCancel:
                actionable
                    ? () async {
                      final ok = await _confirmDestructive(
                        title: 'Cancelar horário?',
                        body:
                            'O horário com ${ag.alunoNome} deixa de aparecer como ativo.',
                        confirmLabel: 'Cancelar horário',
                      );
                      if (!ok) return;
                      await _setStatus(ag, 'CANCELADO');
                    }
                    : null,
            onReschedule: actionable ? () => _reschedule(ag) : null,
            onDelete: () async {
              final ok = await _confirmDestructive(
                title: 'Excluir atendimento?',
                body: 'Isso remove o horário com ${ag.alunoNome} da agenda.',
                confirmLabel: 'Excluir',
              );
              if (!ok) return;
              await ref.read(agendaRepositoryProvider).excluir(ag.id);
              if (!mounted) return;
              Navigator.pop(context);
              await _load(force: true);
              if (!mounted) return;
              AnalyticsService.instance.track(ProductEvents.agendaDeleted);
              FeedbackHelper.showSuccess(context, 'Agendamento excluído.');
            },
          ),
    );
  }
}
