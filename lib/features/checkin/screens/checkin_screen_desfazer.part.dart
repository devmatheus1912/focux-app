part of 'checkin_screen.dart';

/// Faixa "Série N registrada · Desfazer" que some sozinha.
extension _CheckinDesfazer on _CheckinScreenState {
  static const _duracaoFaixa = Duration(seconds: 6);

  void _anotarUltimaSerie(ExecucaoExercicio ee, CheckinSeriePendente serie) {
    _ultimaTimer?.cancel();
    final carga = checkinCargaLabel(serie.cargaKg);
    final reps = serie.repeticoes;
    final partes = [
      if (carga != null) carga,
      if (reps != null && reps.isNotEmpty) '$reps reps',
    ];
    setState(
      () =>
          _ultimaSerie = (
            exercicioId: ee.treinoExercicioId,
            numero: serie.numero,
            detalhe: partes.isEmpty ? null : partes.join(' × '),
          ),
    );
    _ultimaTimer = Timer(_duracaoFaixa, _limparUltimaSerie);
  }

  /// ±15 s no descanso em andamento.
  void _ajustarDescanso(int delta) => setState(() => _descanso.ajustar(delta));

  void _limparUltimaSerie() {
    _ultimaTimer?.cancel();
    if (mounted && _ultimaSerie != null) setState(() => _ultimaSerie = null);
  }

  /// Desfaz a série da faixa e encerra o descanso que ela abriu.
  void _desfazerUltimaSerie() {
    final ultima = _ultimaSerie;
    final exercicios = _execucao?.exercicios ?? const <ExecucaoExercicio>[];
    _limparUltimaSerie();
    if (ultima == null) return;
    for (final ee in exercicios) {
      if (ee.treinoExercicioId == ultima.exercicioId && ee.seriesFeitas > 0) {
        _pularDescanso();
        _desfazer(ee);
        return;
      }
    }
  }
}
