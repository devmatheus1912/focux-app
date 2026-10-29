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

  /// Séries feitas sem carga, sem contar exercícios marcados "sem carga".
  Future<int> _contarSemCarga() async {
    var total = 0;
    for (final ee in _execucao?.exercicios ?? const <ExecucaoExercicio>[]) {
      final sem = ee.seriesDetalhes.where((d) => d.cargaKg == null).length;
      if (sem == 0) continue;
      if (await _CheckinScreenState._semCarga.semCarga(ee.treinoExercicioId)) {
        continue;
      }
      total += sem;
    }
    return total;
  }

  /// Ações do exercício no ⋮ do cabeçalho: tudo que antes ficava espalhado
  /// em "Mais" e "Finalizar treino" no corpo da tela.
  Future<void> _abrirMais(ExecucaoExercicio ee) async {
    final s = S.of(context);
    final livre = !_registrando && !_concluindo;
    final podeRegistrar = checkinPodeRegistrar(ee);
    final faltaSerie =
        livre && ee.series != null && ee.seriesFeitas < ee.series!;
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: s.checkinMaisTitulo,
      subtitulo: ee.exercicioNome,
      grupos: [
        FxActionGroup<String>(null, [
          if (podeRegistrar && livre)
            FxActionItem(
              valor: 'ajustar',
              rotulo: s.checkinAjustar,
              descricao: s.checkinAjustarSub,
              icone: Icons.tune_rounded,
            ),
          if (faltaSerie)
            FxActionItem(
              valor: 'confirmar',
              rotulo: checkinConfirmarRestanteLabel(
                s,
                feitas: ee.seriesFeitas,
                total: ee.series,
              ),
              descricao: s.checkinConfirmarRestanteSub,
              icone: Icons.done_all_rounded,
            ),
          if (livre && ee.seriesFeitas > 0)
            FxActionItem(
              valor: 'desfazer',
              rotulo: s.checkinDesfazerSerie,
              descricao: s.checkinDesfazerSub,
              icone: Icons.undo_rounded,
            ),
          FxActionItem(
            valor: 'finalizar',
            rotulo: s.checkinFinalizarTreino,
            descricao: s.checkinFinalizarSub,
            icone: Icons.flag_rounded,
          ),
        ]),
      ],
    );
    if (escolha == null || !mounted) return;
    switch (escolha) {
      case 'ajustar':
        await _registrarSerieDetalhada(ee);
      case 'confirmar':
        _confirmarRestante(ee);
      case 'desfazer':
        _desfazer(ee);
      case 'finalizar':
        await _finalizar();
    }
  }
}
