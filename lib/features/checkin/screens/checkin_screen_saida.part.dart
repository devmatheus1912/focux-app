part of 'checkin_screen.dart';

/// Sair da execução: continuar depois, encerrar agora ou descartar (com
/// confirmação), e descartar a sessão aberta que bloqueia um treino novo.
extension _CheckinSaida on _CheckinScreenState {
  Future<void> _descartarSessaoAberta() async {
    final execucaoId = _sessaoAberta?.execucaoId;
    if (execucaoId == null) return;
    if (!await showCheckinDescartarAberto(context) || !mounted) return;
    setState(() => _descartandoSessao = true);
    final descartou = await _descartar(execucaoId);
    if (!mounted) return;
    setState(() => _descartandoSessao = false);
    if (descartou) await _iniciar();
  }

  Future<bool> _descartar(int execucaoId) async {
    try {
      await _sessao.descartar(execucaoId);
      checkinSessaoMudou(ref);
      return true;
    } catch (e) {
      if (mounted) _erro(friendlyError(e));
      return false;
    }
  }

  /// Sem nenhuma série: "Já fiz" (conta, sem parcial) ou descartar.
  Future<void> _finalizarSemSeries() async {
    final escolha = await showCheckinSemSeries(context);
    if (escolha == null || !mounted) return;
    final id = _execucao?.id;
    switch (escolha) {
      case CheckinSemSeriesEscolha.jaFiz:
        try {
          await ref
              .read(checkinRepositoryProvider)
              .confirmarPlano(widget.treinoId);
          checkinTreinoConcluido(modo: 'ja_fiz');
          checkinSessaoMudou(ref);
        } catch (e) {
          if (mounted) _erro(friendlyError(e));
          return;
        }
        if (!mounted) return;
        FeedbackHelper.showSuccess(
          context,
          S.of(context).checkinSemSeriesFeito,
        );
      case CheckinSemSeriesEscolha.descartar:
        if (id != null && !await _descartar(id)) return;
    }
    if (mounted) safePopOrGo(context, '/checkin/treinos');
  }

  Future<void> _sair() async {
    if (_concluindo) return;
    FxKeyboardDismissScope.dismiss();
    final exercicios = _execucao?.exercicios ?? [];
    final choice = await showFxExecutionLeaveSheet(
      context,
      hasProgress:
          exercicios.any((e) => e.seriesFeitas > 0) || _duration.inSeconds > 30,
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case FxExecutionLeaveChoice.encerrarAgora:
        await _finalizar();
        return;
      case FxExecutionLeaveChoice.descartar:
        if (!await showCheckinDescartarTreino(context) || !mounted) return;
        final id = _execucao?.id;
        if (id != null && !await _descartar(id)) return;
      case FxExecutionLeaveChoice.continuarDepois:
        break;
    }
    if (mounted) safePopOrGo(context, '/checkin/treinos');
  }
}
