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
      await _repo.descartar(execucaoId);
      await _CheckinScreenState._fila.removerDaExecucao(execucaoId);
      _invalidateSessaoCaches();
      return true;
    } catch (e) {
      if (mounted) _erro(friendlyError(e));
      return false;
    }
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
