part of 'checkin_screen.dart';

/// Faixa "Série N registrada · Desfazer" que some sozinha.
extension _CheckinDesfazer on _CheckinScreenState {
  static const _duracaoFaixa = Duration(seconds: 6);

  void _anotarUltimaSerie(ExecucaoExercicio ee, CheckinSeriePendente serie) {
    _ultimaTimer?.cancel();
    _ultimaEnvio = serie;
    _rpeEscolhido = serie.rpe;
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

  /// Esforço sentido na série que acabou de ser registrada. Reenvia a mesma
  /// série (mesmo número, carga e reps) com o RPE: o servidor grava por número,
  /// então só o esforço muda.
  Future<void> _anotarRpe(int rpe) async {
    final base = _ultimaEnvio;
    if (base == null) return;
    setState(() => _rpeEscolhido = rpe);
    final serie = CheckinSeriePendente(
      execucaoId: base.execucaoId,
      treinoExercicioId: base.treinoExercicioId,
      numero: base.numero,
      cargaKg: base.cargaKg,
      repeticoes: base.repeticoes,
      feedback: base.feedback,
      rpe: rpe,
      dor: base.dor,
    );
    _ultimaEnvio = serie;
    final r = await checkinRegistrarSerie(
      serie: serie,
      store: _CheckinScreenState._fila,
      enviar: checkinEnvioPelo(_repo),
      sessaoAtiva: ref.read(checkinSessaoAtivaProvider),
    );
    if (!mounted) return;
    switch (r) {
      case CheckinRegistroSalvo(:final exercicio):
        _applyUpdated(exercicio);
      case CheckinRegistroNaFila(:final fila):
        setState(
          () => _pendentes = checkinPendentesDaExecucao(fila, serie.execucaoId),
        );
      case CheckinRegistroRecusado():
        setState(() => _rpeEscolhido = null);
    }
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
