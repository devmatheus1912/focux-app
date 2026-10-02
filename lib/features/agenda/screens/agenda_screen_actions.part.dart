part of 'agenda_screen.dart';

extension on _AgendaScreenState {
  void _popRootOverlay() {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }

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

  /// Sucesso, fila offline ou falha: a sheet fecha antes do aviso, senão o
  /// snackbar fica escondido atrás dela. Fila offline não recarrega — no
  /// servidor a agenda ainda não mudou.
  Future<void> _runSheetMutation(
    Future<void> Function() mutation, {
    required String failureFallback,
    required Future<void> Function() onSuccess,
  }) async {
    Object? failure;
    try {
      await mutation();
    } catch (e) {
      failure = e;
    }
    if (!mounted) return;
    _popRootOverlay();
    if (failure != null) {
      FeedbackHelper.showApiFailure(
        context,
        failure,
        fallback: failureFallback,
      );
      return;
    }
    await onSuccess();
  }

  Future<void> _setStatus(Agendamento ag, String status) => _runSheetMutation(
    () => ref.read(agendaRepositoryProvider).atualizarStatus(ag.id, status),
    failureFallback: S.of(context).agendaStatusFalhou,
    onSuccess: () async {
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
    },
  );

  /// Horário recusado pelo servidor (passado/conflito): avisa, recarrega o mês
  /// e reabre a grade, já fora da sheet do atendimento.
  Future<void> _reschedule(
    Agendamento ag, {
    bool fromSheet = true,
    String? aviso,
  }) async {
    final pick = await showAgendaSlotPicker(
      context,
      title: 'Remarcar ${agendaPrimeiroNome(ag.alunoNome)}',
      day: ag.inicio,
      inicio: ag.inicio,
      duracaoMin: ag.fim.difference(ag.inicio).inMinutes,
      agendamentos: agendaMonthOf(ag.inicio) == _mes ? _ags : null,
      loadMonth: _loadMonth,
      excludeId: ag.id,
      aviso: aviso,
    );
    if (pick == null || !mounted) return;
    Object? failure;
    try {
      await ref
          .read(agendaRepositoryProvider)
          .atualizarHorario(ag.id, pick.inicio, pick.fim, titulo: ag.titulo);
    } catch (e) {
      failure = e;
    }
    if (!mounted) return;
    if (fromSheet) _popRootOverlay();
    if (failure == null) {
      await _load(force: true);
      if (!mounted) return;
      AnalyticsService.instance.track(ProductEvents.agendaRescheduled);
      FeedbackHelper.showSuccess(context, 'Horário remarcado.');
      return;
    }
    final slotError = agendaSlotErrorMessage(failure);
    if (slotError == null) {
      FeedbackHelper.showApiFailure(
        context,
        failure,
        fallback: S.of(context).agendaRemarcarFalhou,
      );
      return;
    }
    await _load(force: true);
    if (mounted) await _reschedule(ag, fromSheet: false, aviso: slotError);
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
              _popRootOverlay();
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
            onComplete: actionable ? () => _setStatus(ag, 'CONCLUIDO') : null,
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
              if (!ok || !mounted) return;
              await _runSheetMutation(
                () => ref.read(agendaRepositoryProvider).excluir(ag.id),
                failureFallback: S.of(context).agendaExcluirFalhou,
                onSuccess: () async {
                  await _load(force: true);
                  if (!mounted) return;
                  AnalyticsService.instance.track(ProductEvents.agendaDeleted);
                  FeedbackHelper.showSuccess(context, 'Agendamento excluído.');
                },
              );
            },
          ),
    );
  }
}
