part of 'checkin_screen.dart';

extension _CheckinCarga on _CheckinScreenState {
  /// Sem carga no rascunho e sem histórico: pergunta uma vez, com teclado
  /// direto. "Sem carga" lembra o exercício e não pergunta de novo. Devolve
  /// falso se o aluno fechou a folha (a série não é registrada).
  Future<bool> _garantirCarga(ExecucaoExercicio ee) async {
    if (_rascunhos.de(ee).cargaKg != null) return true;
    if (await _CheckinScreenState._semCarga.semCarga(ee.treinoExercicioId)) return true;
    if (!mounted) return false;
    final s = S.of(context);
    _pedindoRpe = true;
    final FxNumberPadResultado? r;
    try {
      r = await showFxNumberPadSheet(
        context,
        titulo: s.checkinCargaPedidaTitulo,
        subtitulo: ee.exercicioNome,
        confirmarLabel: s.checkinCargaPedidaConfirmar,
        sufixo: s.checkinStepperKg,
        alternativaLabel: s.checkinSemCargaNesteExercicio,
      );
    } finally {
      _pedindoRpe = false;
    }
    if (r == null || !mounted) return false;
    if (r.alternativa) {
      await _CheckinScreenState._semCarga.marcar(ee.treinoExercicioId);
      return true;
    }
    _mexerRascunho(() => _rascunhos.definirCarga(ee, r!.valor!));
    return true;
  }
}
