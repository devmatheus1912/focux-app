part of 'checkin_screen.dart';

/// Layout e leituras da execução; nada aqui chama `setState`.
extension _CheckinCorpo on _CheckinScreenState {
  ExecucaoExercicio _currentExercise(List<ExecucaoExercicio> exercicios) {
    return checkinPickCurrentExercise(
      exercicios: exercicios,
      idOf: (e) => e.treinoExercicioId,
      concluidoOf: (e) => e.concluido,
      focoId: _focoTreinoExercicioId,
    );
  }

  String? _proximaSerieLinha() {
    final exercicios = _execucao?.exercicios ?? const <ExecucaoExercicio>[];
    if (exercicios.isEmpty) return null;
    final ee = _currentExercise(exercicios);
    return checkinRestContextLine(
      S.of(context),
      exerciseName: ee.exercicioNome,
      seriesFeitas: ee.seriesFeitas,
      series: ee.series,
    );
  }

  /// Erro flutua acima do rodapé e do aviso de pendentes.
  void _erro(String mensagem) => FeedbackHelper.showError(
    context,
    mensagem,
    reserveBottom: checkinRodapeReserva(
      comPendentes: _pendentes > 0,
      textScaler: MediaQuery.textScalerOf(context),
    ),
  );

  void _continuarSessaoAberta() {
    final treinoId = _sessaoAberta?.treinoId;
    if (treinoId == null) {
      safePopOrGo(context, '/checkin/treinos');
      return;
    }
    context.pushReplacement('/checkin/executar', extra: treinoId);
  }

  Widget _executionShell({required Widget body, bool guard = false}) {
    final scaffold = fxScreenA11yScope(
      label: S.of(context).checkinTelaA11y,
      child: FxShellScaffold(
        useMesh: false,
        constrainWidth: false,
        safeArea: false,
        body: body,
      ),
    );
    return FxExecutionKeepAwake(
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child:
            guard
                ? FxExecutionPopGuard(onLeave: _sair, child: scaffold)
                : scaffold,
      ),
    );
  }

  Widget _execucaoBody() {
    final s = S.of(context);
    final exercicios = _execucao?.exercicios ?? const <ExecucaoExercicio>[];
    final current = exercicios.isEmpty ? null : _currentExercise(exercicios);
    final currentIndex = current == null ? 0 : exercicios.indexOf(current) + 1;
    final tudoFeito =
        exercicios.isNotEmpty && checkinExerciciosFaltando(exercicios) == 0;
    final onTrocar =
        exercicios.length > 1 ? () => _abrirFila(exercicios) : null;
    final rodape = _rodape(s, current, tudoFeito: tudoFeito);

    return Column(
      children: [
        CheckinWorkoutHeader(
          treinoNome: _execucao?.treinoNome ?? s.checkinTreinoFallback,
          contextLine:
              _descanso.ativo
                  ? s.checkinDescanso
                  : checkinChromeContextLine(
                    s,
                    duration: checkinDurationLabel(_duration),
                    current: currentIndex,
                    total: exercicios.length,
                  ),
          onBack: _sair,
          onHelp:
              current != null && checkinExerciseHasTips(current)
                  ? () => showCheckinExerciseTipsSheet(context, ee: current)
                  : null,
        ),
        Expanded(
          child:
              _descanso.ativo
                  ? CheckinRestFocusView(
                    seconds: _descanso.segundos,
                    totalSeconds: _descanso.total,
                    contextLine: _proximaSerieLinha(),
                    onSkip: _pularDescanso,
                    onTrocar: onTrocar,
                  )
                  : _cardOuVazio(
                    s,
                    exercicios,
                    current,
                    currentIndex,
                    onTrocar,
                  ),
        ),
        if (_pendentes > 0)
          CheckinPendentesAviso(
            pendentes: _pendentes,
            onTentar: () => _enviarFila(),
          ),
        if (rodape != null) rodape,
      ],
    );
  }

  Widget? _rodape(S s, ExecucaoExercicio? current, {required bool tudoFeito}) {
    final rodape = checkinRodape(
      descansando: _descanso.ativo,
      tudoFeito: tudoFeito,
      atual: current,
    );
    return switch (rodape) {
      CheckinRodape.nenhum => null,
      CheckinRodape.registrar => CheckinRodapeBar(
        label: checkinRegistrarLabel(s, first: current!.seriesFeitas <= 0),
        loading: _registrando || _concluindo,
        loadingLabel:
            _concluindo ? s.checkinFinalizando : s.checkinSalvandoSerie,
        onPressed: () => _registrarSerieRapida(current),
      ),
      CheckinRodape.finalizar => CheckinRodapeBar(
        label: s.checkinFinalizarTreino,
        icon: Icons.flag_rounded,
        loading: _concluindo,
        loadingLabel: s.checkinFinalizando,
        onPressed: _finalizar,
      ),
    };
  }

  Widget _cardOuVazio(
    S s,
    List<ExecucaoExercicio> exercicios,
    ExecucaoExercicio? current,
    int currentIndex,
    VoidCallback? onTrocar,
  ) {
    if (exercicios.isEmpty) {
      return FxEmptyState(
        icon: 'dumbbell',
        title: s.checkinSemExerciciosTitulo,
        subtitle: s.checkinSemExerciciosTexto,
      );
    }
    if (current == null) {
      return FxEmptyState(
        icon: 'dumbbell',
        title: s.checkinNenhumAtivoTitulo,
        subtitle: s.checkinNenhumAtivoTexto,
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _card(current, currentIndex, exercicios.length, onTrocar),
            if (checkinExerciciosFaltando(exercicios) > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FxSettingsLayout.pageInset,
                ),
                child: CheckinFinalizarLink(
                  concluindo: _concluindo,
                  onFinalizar: _finalizar,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    ExecucaoExercicio current,
    int currentIndex,
    int total,
    VoidCallback? onTrocar,
  ) {
    final draft = _rascunhos.de(current);
    // Mexer em série já gravada durante um envio embaralha a numeração.
    final livre = !_registrando && !_concluindo;
    final faltaSerie =
        livre &&
        current.series != null &&
        current.seriesFeitas < current.series!;
    return CheckinSerieCard(
      key: ValueKey(current.treinoExercicioId),
      ee: current,
      index: currentIndex,
      total: total,
      draftCargaKg: draft.cargaKg,
      draftReps: draft.reps,
      onPlusCarga:
          () => _mexerRascunho(() => _rascunhos.somarCarga(current, 2.5)),
      onMinusCarga:
          () => _mexerRascunho(() => _rascunhos.somarCarga(current, -2.5)),
      onPlusReps: () => _mexerRascunho(() => _rascunhos.somarReps(current, 1)),
      onMinusReps:
          () => _mexerRascunho(() => _rascunhos.somarReps(current, -1)),
      onAjustar: () => _registrarSerieDetalhada(current),
      onConfirmarRestante:
          faltaSerie ? () => _confirmarRestante(current) : null,
      onTrocar: onTrocar,
      onDesfazer:
          livre && current.seriesFeitas > 0 ? () => _desfazer(current) : null,
    );
  }
}
