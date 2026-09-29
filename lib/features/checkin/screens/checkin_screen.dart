import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/a11y_announce.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_execution_chrome.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/utils/aluno360_client_cache.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../evolucao/utils/evolucao_home_client_cache.dart';
import '../data/checkin_repository.dart';
import '../data/checkin_series_pendentes.dart';
import '../providers/checkin_provider.dart';
import '../services/checkin_descanso_alerta.dart';
import '../services/checkin_fila_sync.dart';
import '../utils/checkin_descanso_relogio.dart';
import '../utils/checkin_execucao_display.dart';
import '../utils/checkin_execucao_estado.dart';
import '../utils/checkin_exercise_tips.dart';
import '../utils/checkin_serie_input.dart';
import '../utils/checkin_series_fila.dart';
import '../utils/checkin_sessao_aberta.dart';
import '../widgets/checkin_execucao_estados.dart';
import '../widgets/checkin_execucao_sheets.dart';
import '../widgets/checkin_exercise_widgets.dart';
import '../widgets/checkin_header_widgets.dart';
import '../widgets/checkin_serie_campos_widgets.dart';
import '../widgets/checkin_serie_detail_widgets.dart';
import '../widgets/checkin_sessao_aberta_state.dart';
import '../widgets/checkin_timer_widgets.dart';

part 'checkin_screen_corpo.part.dart';
part 'checkin_screen_saida.part.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  final int treinoId;
  const CheckinScreen({super.key, required this.treinoId});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen>
    with WidgetsBindingObserver {
  static const _fila = CheckinSeriesPendentesStore();

  ExecucaoTreino? _execucao;
  bool _loading = true;
  String? _loadError;
  CheckinSessaoAberta? _sessaoAberta;
  bool _descartandoSessao = false;
  bool _concluindo = false;
  bool _registrando = false;

  /// Segura o 2º toque enquanto o pedido de RPE está aberto, sem "Salvando…".
  bool _pedindoRpe = false;
  bool _iniciarInFlight = false;
  Timer? _timer;
  Duration _duration = Duration.zero;
  DateTime _startedAt = DateTime.now();
  int? _focoTreinoExercicioId;
  final _rascunhos = CheckinRascunhos();
  int _pendentes = 0;
  StreamSubscription<void>? _conexaoSub;
  late final ProviderSubscription<CheckinDescansoAlerta> _alerta;
  late final _descanso = CheckinDescansoRelogio(
    agora: _agora,
    onTick: () {
      if (mounted) setState(() {});
    },
    onFim: _avisarFimDescanso,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _alerta = ref.listenManual(checkinDescansoAlertaProvider, (_, _) {});
    _conexaoSub = ref
        .read(checkinConexaoVoltouProvider)
        .listen((_) => _enviarFila());
    _iniciar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _conexaoSub?.cancel();
    _timer?.cancel();
    _descanso.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    setState(() => _duration = _agora().difference(_startedAt));
    _descanso.sincronizar();
    _enviarFila();
  }

  DateTime _agora() => ref.read(checkinRelogioProvider)();

  CheckinRepository get _repo => ref.read(checkinRepositoryProvider);

  Future<void> _iniciar() async {
    if (_loading && _execucao != null) return;
    if (_iniciarInFlight) return;
    _iniciarInFlight = true;
    setState(() {
      _loading = true;
      _loadError = null;
      _sessaoAberta = null;
    });
    try {
      final recebida = await _repo.iniciar(widget.treinoId);
      final fila = await _fila.ler();
      if (!mounted) return;
      final execucao = checkinAplicarPendentes(recebida, fila);
      setState(() {
        _execucao = execucao;
        _pendentes = checkinPendentesDaExecucao(fila, execucao.id);
        _loading = false;
      });
      _iniciarRelogio(execucao);
      unawaited(_enviarFila());
    } catch (e) {
      if (!mounted) return;
      final sessao = CheckinSessaoAberta.fromError(e);
      setState(() {
        _loading = false;
        _sessaoAberta = sessao;
        _loadError = sessao == null ? friendlyError(e) : null;
      });
    } finally {
      _iniciarInFlight = false;
    }
  }

  void _iniciarRelogio(ExecucaoTreino execucao) {
    final agora = _agora();
    _startedAt = checkinInicioCronometro(execucao.iniciadoEm, agora);
    _duration = agora.difference(_startedAt);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _duration = _agora().difference(_startedAt));
    });
  }

  /// Recusa do servidor é avisada pelo escopo global da fila; aqui só o
  /// estado da tela acompanha a rodada.
  Future<bool> _enviarFila() async {
    final CheckinFilaResultado r;
    try {
      r = await ref.read(checkinFilaSyncProvider).enviar();
    } catch (_) {
      return false;
    }
    if (!mounted) return false;
    final base = _execucao;
    ExecucaoTreino? atual;
    if (base != null) {
      var t = base;
      for (final e in r.enviadas) {
        if (e.execucaoId == t.id) t = checkinComExercicio(t, e.exercicio);
      }
      atual = checkinAplicarPendentes(t, r.restantes);
    }
    setState(() {
      _execucao = atual;
      _pendentes = checkinPendentesDaExecucao(r.restantes, atual?.id);
    });
    if (r.rejeitadas > 0) await _recarregar();
    return _pendentes == 0;
  }

  /// Série recusada saiu da fila: o estado local volta ao do servidor.
  Future<void> _recarregar() async {
    final id = _execucao?.id;
    if (id == null) return;
    try {
      final servidor = await _repo.detalhe(id);
      final fila = await _fila.ler();
      if (!mounted) return;
      setState(() => _execucao = checkinAplicarPendentes(servidor, fila));
    } catch (_) {}
  }

  Future<bool> _filaLimpa() async {
    if (_pendentes == 0) return true;
    final ok = await _enviarFila();
    if (!ok && mounted) {
      _erro(S.of(context).checkinPendentesBloqueio);
    }
    return ok;
  }

  /// Desfazer e confirmar restante mexem em série já gravada: fila vazia antes.
  Future<void> _atualizar(
    Future<ExecucaoExercicio> Function(int execucaoId) chamada,
  ) async {
    final id = _execucao?.id;
    if (id == null || !await _filaLimpa()) return;
    try {
      HapticFeedback.selectionClick();
      final updated = await chamada(id);
      if (mounted) _applyUpdated(updated);
    } catch (e) {
      if (mounted) _erro(friendlyError(e));
    }
  }

  void _desfazer(ExecucaoExercicio ee) => _atualizar(
    (id) => _repo.marcarExercicio(
      id,
      ee.treinoExercicioId,
      ee.seriesFeitas - 1,
      feedback: ee.feedback,
      rpe: ee.rpe,
      dor: ee.dor,
    ),
  );

  void _confirmarRestante(ExecucaoExercicio ee) =>
      _atualizar((id) => _repo.confirmarRestante(id, ee.treinoExercicioId));

  void _mexerRascunho(VoidCallback mudanca) => setState(mudanca);

  int _proximoNumero(ExecucaoExercicio ee) =>
      (ee.seriesFeitas + 1).clamp(1, ee.series ?? 999);

  Future<void> _registrarSerieRapida(ExecucaoExercicio ee) async {
    final id = _execucao?.id;
    if (id == null || _registrando || _pedindoRpe) return;
    final draft = _rascunhos.de(ee);
    int? rpe;
    if (ee.rpeAlvo != null) {
      _pedindoRpe = true;
      try {
        rpe = await showCheckinRpeAlvoPrompt(context, rpeAlvo: ee.rpeAlvo!);
      } finally {
        _pedindoRpe = false;
      }
      if (rpe == null || !mounted) return;
    }
    await _enviarSerie(
      ee,
      CheckinSeriePendente(
        execucaoId: id,
        treinoExercicioId: ee.treinoExercicioId,
        numero: _proximoNumero(ee),
        cargaKg: draft.cargaKg,
        repeticoes: draft.reps == null ? null : '${draft.reps}',
        rpe: rpe,
      ),
    );
  }

  Future<void> _registrarSerieDetalhada(ExecucaoExercicio ee) async {
    final id = _execucao?.id;
    if (id == null || _registrando) return;
    final numero = _proximoNumero(ee);
    final payload = await showCheckinSerieDetalhe(
      context,
      ee: ee,
      numero: numero,
      draft: _rascunhos.de(ee),
    );
    if (payload == null || !mounted) return;
    await _enviarSerie(
      ee,
      CheckinSeriePendente(
        execucaoId: id,
        treinoExercicioId: ee.treinoExercicioId,
        numero: numero,
        cargaKg: payload.cargaKg,
        repeticoes: payload.repeticoes,
        feedback: payload.feedback,
        rpe: payload.rpe,
        dor: payload.dor,
      ),
    );
  }

  /// Falha transitória guarda a série no aparelho: conta como feita e o
  /// descanso começa igual. Recusa mostra a mensagem e mantém o digitado.
  Future<void> _enviarSerie(
    ExecucaoExercicio ee,
    CheckinSeriePendente serie,
  ) async {
    setState(() => _registrando = true);
    final r = await checkinRegistrarSerie(
      serie: serie,
      store: _fila,
      enviar: checkinEnvioPelo(_repo),
      sessaoAtiva: ref.read(checkinSessaoAtivaProvider),
    );
    if (!mounted) return;
    setState(() => _registrando = false);
    final ExecucaoExercicio depois;
    switch (r) {
      case CheckinRegistroRecusado(:final erro):
        _rascunhos.manter(
          ee,
          cargaKg: serie.cargaKg,
          repeticoes: serie.repeticoes,
        );
        _erro(friendlyError(erro));
        return;
      case CheckinRegistroSalvo(:final exercicio):
        depois = exercicio;
        _applyUpdated(depois);
        if (_pendentes > 0) unawaited(_enviarFila());
      case CheckinRegistroNaFila(:final fila):
        depois = checkinAplicarSerieLocal(ee, serie);
        _applyUpdated(depois);
        setState(
          () => _pendentes = checkinPendentesDaExecucao(fila, serie.execucaoId),
        );
    }
    HapticFeedback.selectionClick();
    if (serie.numero > ee.seriesFeitas) {
      _iniciarDescanso(depois.descansoSegundos ?? 60);
    }
  }

  void _iniciarDescanso(int seconds) {
    setState(() => _descanso.iniciar(seconds));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = S.of(context);
      final ctx = _proximaSerieLinha();
      fxAnnounce(
        context,
        ctx == null ? s.checkinDescanso : s.checkinDescansoCom(ctx),
      );
    });
  }

  void _pularDescanso() => setState(_descanso.parar);

  void _avisarFimDescanso() {
    final estado = WidgetsBinding.instance.lifecycleState;
    if (!mounted) return;
    if (estado != null && estado != AppLifecycleState.resumed) return;
    unawaited(_alerta.read().tocar());
    final s = S.of(context);
    final ctx = _proximaSerieLinha();
    fxAnnounce(
      context,
      ctx == null ? s.checkinDescansoAcabou : s.checkinDescansoAcabouCom(ctx),
    );
  }

  Future<void> _finalizar() async {
    if (_execucao == null || !await _filaLimpa() || !mounted) return;
    final faltam = checkinExerciciosFaltando(_execucao!.exercicios);
    if (faltam > 0 &&
        !await showCheckinFinalizarIncompleto(context, faltam: faltam)) {
      return;
    }
    if (mounted) await _concluir();
  }

  /// Concluir é idempotente: retry depois de timeout volta 200 sem evolução
  /// (ou o 400 "já foi concluído" do backend antigo) e segue como sucesso.
  Future<void> _concluir() async {
    setState(() => _concluindo = true);
    try {
      final id = _execucao!.id!;
      final concluida = await checkinConcluir(() => _repo.concluir(id));
      _invalidateSessaoCaches();
      if (!mounted) return;
      await showCheckinResultado(context, concluida: concluida);
      if (mounted) safePopOrGo(context, '/checkin/treinos');
    } catch (e) {
      if (mounted) _erro(friendlyError(e));
    } finally {
      if (mounted) setState(() => _concluindo = false);
    }
  }

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

  void _invalidateSessaoCaches() {
    EvolucaoHomeClientCache.clear();
    Aluno360ClientCache.clear();
    invalidateAlunoDashboardHome(ref);
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return _executionShell(body: const CheckinPreparandoView());
    final sessaoAberta = _sessaoAberta;
    if (sessaoAberta != null) {
      return _executionShell(
        body: SafeArea(
          child: CheckinSessaoAbertaState(
            sessao: sessaoAberta,
            descartando: _descartandoSessao,
            onContinuar: _continuarSessaoAberta,
            onDescartar:
                sessaoAberta.execucaoId == null ? null : _descartarSessaoAberta,
            onVoltar: () => safePopOrGo(context, '/checkin/treinos'),
          ),
        ),
      );
    }
    final erro = _loadError;
    if (erro != null) {
      return _executionShell(
        body: CheckinIniciarErroView(
          mensagem: erro,
          onRetry: _iniciar,
          onVoltar: () => safePopOrGo(context, '/checkin/treinos'),
        ),
      );
    }
    return _executionShell(guard: true, body: _execucaoBody());
  }
}
