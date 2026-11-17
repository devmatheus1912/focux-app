part of 'checkin_screen.dart';

/// Atualizar um exercício na sessão e trocar o exercício em foco ("Fazer outro
/// da lista agora").
extension _CheckinFoco on _CheckinScreenState {
  void _applyUpdated(ExecucaoExercicio updated) {
    if (_execucao == null) return;
    setState(() {
      _execucao = checkinComExercicio(_execucao!, updated);
      if (updated.concluido &&
          updated.treinoExercicioId == _focoTreinoExercicioId) {
        _focoTreinoExercicioId = null;
      }
    });
  }

  Future<void> _abrirFila(List<ExecucaoExercicio> exercicios) async {
    final currentId = _currentExercise(exercicios).treinoExercicioId;
    final picked = await showCheckinFilaSheet(
      context,
      exercicios: exercicios,
      selectedId: currentId,
    );
    if (picked == null || !mounted || picked == currentId) return;
    setState(() {
      _descanso.parar();
      _focoTreinoExercicioId = picked;
    });
  }
}
