import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_celebration_overlay.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_execution_chrome.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../alunos/utils/aluno360_client_cache.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../evolucao/utils/evolucao_home_client_cache.dart';
import '../data/checkin_repository.dart';
import '../data/meus_treinos_mem_cache.dart';
import '../providers/checkin_provider.dart';
import '../utils/checkin_execucao_display.dart';
import '../utils/checkin_serie_input.dart';
import '../widgets/checkin_exercise_widgets.dart';
import '../widgets/checkin_execucao_sheets.dart';
import '../widgets/checkin_header_widgets.dart';
import '../widgets/checkin_serie_detail_widgets.dart';
import '../widgets/checkin_timer_widgets.dart';
import '../utils/checkin_exercise_tips.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  final int treinoId;
  const CheckinScreen({super.key, required this.treinoId});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen>
    with WidgetsBindingObserver {
  ExecucaoTreino? _execucao;
  bool _loading = true;
  String? _loadError;
  bool _concluindo = false;
  bool _iniciarInFlight = false;
  Timer? _timer;
  Duration _duration = Duration.zero;
  bool _showRestTimer = false;
  int _restSeconds = 60;
  DateTime? _restEndsAt;
  Timer? _restTimer;
  int? _focoTreinoExercicioId;
  DateTime _startedAt = DateTime.now();
  final Map<String, CheckinCurrentSetSeed> _drafts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncClocks();
  }

  void _syncClocks() {
    if (!mounted) return;
    setState(() {
      _duration = DateTime.now().difference(_startedAt);
      if (_showRestTimer && _restEndsAt != null) {
        _restSeconds = checkinRestRemaining(endsAt: _restEndsAt!);
        if (_restSeconds <= 0) {
          _restTimer?.cancel();
          _showRestTimer = false;
        }
      }
    });
  }

  Future<void> _iniciar() async {
    if (_loading && _execucao != null) return;
    if (_iniciarInFlight) return;
    _iniciarInFlight = true;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final execucao = await ref
          .read(checkinRepositoryProvider)
          .iniciar(widget.treinoId);
      if (!mounted) return;
      // BE: CONCLUIDO antigo → nova execução EM_ANDAMENTO (idempotência só
      // retoma EM_ANDAMENTO). Não celebrar/sair no start.
      setState(() {
        _execucao = execucao;
        _loading = false;
      });
      _startedAt =
          execucao.iniciadoEm == null
              ? DateTime.now()
              : DateTime.parse(execucao.iniciadoEm!).toLocal();
      _duration = DateTime.now().difference(_startedAt);
      // Sessão zumbi (relógio aberto dias) — timer de UI recomeça, não mostra 28h.
      if (_duration.inHours >= 8) {
        _startedAt = DateTime.now();
        _duration = Duration.zero;
      }
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _duration = DateTime.now().difference(_startedAt);
        });
      });
    } catch (e) {
      if (!mounted) return;
      final msg = friendlyError(e);
      final sessaoAberta =
          msg.toLowerCase().contains('treino em aberto') ||
          msg.toLowerCase().contains('descarte antes');
      setState(() {
        _loading = false;
        _loadError =
            sessaoAberta
                ? 'Você já tem um treino em andamento. Volte e retome ou descarte antes de iniciar outro.'
                : msg;
      });
    } finally {
      _iniciarInFlight = false;
    }
  }

  Future<void> _marcar(ExecucaoExercicio ee, int seriesFeitas) async {
    if (_execucao == null) return;
    final next = seriesFeitas.clamp(0, ee.series ?? 999);
    try {
      HapticFeedback.selectionClick();
      final updated = await ref
          .read(checkinRepositoryProvider)
          .marcarExercicio(
            _execucao!.id!,
            ee.treinoExercicioId,
            next,
            feedback: ee.feedback,
            rpe: ee.rpe,
            dor: ee.dor,
          );
      if (!mounted) return;
      _applyUpdated(updated);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  String _draftKey(ExecucaoExercicio ee) =>
      '${ee.treinoExercicioId}-${ee.seriesFeitas + 1}';

  CheckinCurrentSetSeed _draftFor(ExecucaoExercicio ee) {
    return _drafts[_draftKey(ee)] ??
        checkinCurrentSetSeed(ee: ee, numero: ee.seriesFeitas + 1);
  }

  void _writeDraft(ExecucaoExercicio ee, CheckinCurrentSetSeed seed) {
    setState(() => _drafts[_draftKey(ee)] = seed);
  }

  void _bumpCarga(ExecucaoExercicio ee, double delta) {
    final current = _draftFor(ee);
    final next = ((current.cargaKg ?? 0) + delta).clamp(0, 500).toDouble();
    _writeDraft(ee, CheckinCurrentSetSeed(cargaKg: next, reps: current.reps));
  }

  void _bumpReps(ExecucaoExercicio ee, int delta) {
    final current = _draftFor(ee);
    final next = ((current.reps ?? 0) + delta).clamp(0, 50).toInt();
    _writeDraft(
      ee,
      CheckinCurrentSetSeed(cargaKg: current.cargaKg, reps: next),
    );
  }

  Future<void> _registrarSerieRapida(ExecucaoExercicio ee) async {
    if (_execucao == null) return;
    final numero = (ee.seriesFeitas + 1).clamp(1, ee.series ?? 999);
    final draft = _draftFor(ee);
    int? rpe;
    if (ee.rpeAlvo != null) {
      rpe = await showCheckinRpeAlvoPrompt(context, rpeAlvo: ee.rpeAlvo!);
      if (rpe == null || !mounted) return;
    }
    try {
      HapticFeedback.selectionClick();
      final updated = await ref
          .read(checkinRepositoryProvider)
          .registrarSerie(
            _execucao!.id!,
            ee.treinoExercicioId,
            numero: numero,
            cargaKg: draft.cargaKg,
            repeticoes: draft.reps == null ? null : '${draft.reps}',
            rpe: rpe,
          );
      if (!mounted) return;
      _applyUpdated(updated);
      if (numero > ee.seriesFeitas) {
        _startRestTimer(ee.descansoSegundos ?? 60);
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _confirmarRestante(ExecucaoExercicio ee) async {
    if (_execucao == null) return;
    try {
      HapticFeedback.selectionClick();
      final updated = await ref
          .read(checkinRepositoryProvider)
          .confirmarRestante(_execucao!.id!, ee.treinoExercicioId);
      if (!mounted) return;
      _applyUpdated(updated);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _registrarSerieDetalhada(
    ExecucaoExercicio ee, {
    required int numero,
    ExecucaoSerie? serie,
  }) async {
    if (_execucao == null) return;
    final total = ee.series ?? numero;
    final safeNumero = numero.clamp(1, total).toInt();
    final payload = await showFxHomeSheet<CheckinSeriePayload>(
      context,
      builder:
          (context) => CheckinSerieDetailSheet(
            title: 'Série $safeNumero',
            initialCargaKg:
                serie?.cargaKg ?? _draftFor(ee).cargaKg ?? ee.cargaKg,
            initialRepeticoes:
                serie?.repeticoes ??
                (_draftFor(ee).reps == null ? null : '${_draftFor(ee).reps}') ??
                checkinSerieRepsSeed(
                  serieRepeticoes: null,
                  prescricacao: ee.repeticoes,
                ),
            prescricacaoHint: checkinSeriePrescricaoHint(ee.repeticoes),
            initialFeedback: serie?.feedback ?? ee.feedback,
            initialRpe: serie?.rpe ?? ee.rpe,
            rpeAlvo: ee.rpeAlvo,
            initialDor: serie?.dor ?? ee.dor,
          ),
    );
    if (payload == null) return;

    try {
      HapticFeedback.selectionClick();
      final updated = await ref
          .read(checkinRepositoryProvider)
          .registrarSerie(
            _execucao!.id!,
            ee.treinoExercicioId,
            numero: safeNumero,
            cargaKg: payload.cargaKg,
            repeticoes: payload.repeticoes,
            feedback: payload.feedback,
            rpe: payload.rpe,
            dor: payload.dor,
          );
      if (!mounted) return;
      _applyUpdated(updated);
      if (safeNumero > ee.seriesFeitas) {
        _startRestTimer(ee.descansoSegundos ?? 60);
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    final clamped = seconds.clamp(15, 600).toInt();
    setState(() {
      _showRestTimer = true;
      _restEndsAt = DateTime.now().add(Duration(seconds: clamped));
      _restSeconds = clamped;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _restEndsAt == null) return;
      final left = checkinRestRemaining(endsAt: _restEndsAt!);
      if (left <= 0) {
        _restTimer?.cancel();
        setState(() {
          _showRestTimer = false;
        });
      } else {
        setState(() {
          _restSeconds = left;
        });
      }
    });
  }

  Future<void> _concluir() async {
    if (_execucao == null) return;
    setState(() {
      _concluindo = true;
    });
    try {
      final concluida = await ref
          .read(checkinRepositoryProvider)
          .concluir(_execucao!.id!);
      MeusTreinosMemCache.clear();
      EvolucaoHomeClientCache.clear();
      Aluno360ClientCache.clear();
      ref.invalidate(historicoCheckinProvider);
      ref.invalidate(meusTreinosProvider);
      ref.invalidate(alunoDashboardHomeProvider);
      if (!mounted) return;
      final evolucoes =
          concluida.evolucoesPerformance.isNotEmpty
              ? concluida.evolucoesPerformance
              : concluida.evolucoesCarga
                  .map(
                    (e) => EvolucaoPerformance(
                      tipo: 'CARGA',
                      exercicioId: e.exercicioId,
                      exercicioNome: e.exercicioNome,
                      valorAnterior: e.cargaAnteriorKg,
                      valorAtual: e.cargaAtualKg,
                      diferenca: e.diferencaKg,
                      percentual: e.percentual,
                      unidade: 'kg',
                      mensagem: e.mensagem,
                    ),
                  )
                  .toList();
      if (evolucoes.isNotEmpty) {
        await showCheckinEvolucaoSheet(context, evolucoes: evolucoes);
        if (!mounted) return;
      } else {
        await FxCelebrationOverlay.show(
          context,
          title: 'Treino concluído!',
          subtitle: 'Sequência conta a semana, não o dia. Descanso não zera.',
          icon: Icons.check_circle_rounded,
        );
      }
      if (!mounted) return;
      safePopOrGo(context, '/checkin/treinos');
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _concluindo = false;
        });
      }
    }
  }

  void _applyUpdated(ExecucaoExercicio updated) {
    if (_execucao == null) return;
    setState(() {
      _execucao = ExecucaoTreino(
        id: _execucao!.id,
        treinoId: _execucao!.treinoId,
        treinoNome: _execucao!.treinoNome,
        status: _execucao!.status,
        iniciadoEm: _execucao!.iniciadoEm,
        concluidoEm: _execucao!.concluidoEm,
        evolucoesCarga: _execucao!.evolucoesCarga,
        evolucoesPerformance: _execucao!.evolucoesPerformance,
        exercicios:
            _execucao!.exercicios
                .map((e) => e.id == updated.id ? updated : e)
                .toList(),
      );
      if (updated.concluido &&
          updated.treinoExercicioId == _focoTreinoExercicioId) {
        _focoTreinoExercicioId = null;
      }
    });
  }

  ExecucaoExercicio _currentExercise(List<ExecucaoExercicio> exercicios) {
    return checkinPickCurrentExercise(
      exercicios: exercicios,
      idOf: (e) => e.treinoExercicioId,
      concluidoOf: (e) => e.concluido,
      focoId: _focoTreinoExercicioId,
    );
  }

  Future<void> _sair() async {
    FxKeyboardDismissScope.dismiss();
    final exercicios = _execucao?.exercicios ?? [];
    final doneSeries = exercicios.fold<int>(
      0,
      (sum, e) => sum + e.seriesFeitas,
    );
    final choice = await showFxExecutionLeaveSheet(
      context,
      hasProgress: doneSeries > 0 || _duration.inSeconds > 30,
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case FxExecutionLeaveChoice.encerrarAgora:
        await _concluir();
        return;
      case FxExecutionLeaveChoice.descartar:
        final id = _execucao?.id;
        if (id != null) {
          try {
            await ref.read(checkinRepositoryProvider).descartar(id);
            MeusTreinosMemCache.clear();
            EvolucaoHomeClientCache.clear();
            Aluno360ClientCache.clear();
            ref.invalidate(historicoCheckinProvider);
            ref.invalidate(meusTreinosProvider);
            ref.invalidate(alunoDashboardHomeProvider);
          } catch (e) {
            if (mounted) {
              FeedbackHelper.showError(context, friendlyError(e));
            }
            return;
          }
        }
        break;
      case FxExecutionLeaveChoice.continuarDepois:
        break;
    }
    if (!mounted) return;
    safePopOrGo(context, '/checkin/treinos');
  }

  Future<void> _abrirFila(List<ExecucaoExercicio> exercicios) async {
    final currentId = _currentExercise(exercicios).treinoExercicioId;
    final picked = await showCheckinFilaSheet(
      context,
      exercicios: exercicios,
      selectedId: currentId,
    );
    if (picked == null || !mounted || picked == currentId) return;
    _restTimer?.cancel();
    setState(() {
      _showRestTimer = false;
      _focoTreinoExercicioId = picked;
    });
  }

  Widget _executionShell({required Widget body}) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return FxExecutionKeepAwake(
      child: ColoredBox(
        color: bg,
        child: fxScreenA11yScope(
          label: 'Checkin',
          child: FxShellScaffold(
            useMesh: false,
            constrainWidth: false,
            safeArea: false,
            body: body,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final dark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final brand = dark ? BrandPalette.accent(primary) : primary;
    final mute = chrome.mute;

    if (_loading) {
      return _executionShell(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FxLoading(color: brand, size: 32),
              const SizedBox(height: TokensStrip.s3),
              Text(
                'Preparando seu treino…',
                style: TextStyle(color: mute, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadError != null) {
      return _executionShell(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FxErrorState(
                  chromeOnDark: dark,
                  primary: brand,
                  title: 'Não foi possível iniciar',
                  message: _loadError!,
                  onRetry: _iniciar,
                ),
                TextButton(
                  onPressed: () => safePopOrGo(context, '/checkin/treinos'),
                  child: Text(
                    'Voltar aos treinos',
                    style: TextStyle(color: mute),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final exercicios = _execucao?.exercicios ?? [];
    final current = exercicios.isEmpty ? null : _currentExercise(exercicios);
    final currentIndex = current == null ? 0 : exercicios.indexOf(current) + 1;
    final allDone =
        exercicios.isNotEmpty && exercicios.every((e) => e.concluido);

    return FxExecutionKeepAwake(
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: FxExecutionPopGuard(
          onLeave: _sair,
          child: fxScreenA11yScope(
            label: 'Checkin',
            child: FxShellScaffold(
              useMesh: false,
              constrainWidth: false,
              safeArea: false,
              body: Column(
                children: [
                  CheckinWorkoutHeader(
                    treinoNome: _execucao?.treinoNome ?? 'Treino',
                    contextLine: checkinChromeContextLine(
                      duration: checkinDurationLabel(_duration),
                      current: currentIndex,
                      total: exercicios.length,
                    ),
                    onBack: _sair,
                    onHelp:
                        current != null && checkinExerciseHasTips(current)
                            ? () => showCheckinExerciseTipsSheet(
                              context,
                              ee: current,
                            )
                            : null,
                  ),
                  if (_showRestTimer)
                    CheckinRestBanner(
                      seconds: _restSeconds,
                      onSkip: () {
                        _restTimer?.cancel();
                        setState(() => _showRestTimer = false);
                      },
                      onTrocar:
                          exercicios.length > 1
                              ? () => _abrirFila(exercicios)
                              : null,
                    ),
                  Expanded(
                    child:
                        exercicios.isEmpty
                            ? const FxEmptyState(
                              icon: 'dumbbell',
                              title: 'Treino sem exercícios',
                              subtitle:
                                  'Seu personal ainda não liberou a lista de exercícios deste treino.',
                            )
                            : current == null
                            ? const FxEmptyState(
                              icon: 'dumbbell',
                              title: 'Nenhum exercício ativo',
                              subtitle:
                                  'Volte à lista de treinos e tente de novo.',
                            )
                            : Align(
                              alignment: Alignment.topCenter,
                              child: SingleChildScrollView(
                                child: CheckinSerieCard(
                                  key: ValueKey(current.treinoExercicioId),
                                  ee: current,
                                  index: currentIndex,
                                  total: exercicios.length,
                                  draftCargaKg: _draftFor(current).cargaKg,
                                  draftReps: _draftFor(current).reps,
                                  onPlusCarga: () => _bumpCarga(current, 2.5),
                                  onMinusCarga: () => _bumpCarga(current, -2.5),
                                  onPlusReps: () => _bumpReps(current, 1),
                                  onMinusReps: () => _bumpReps(current, -1),
                                  onRegistrar:
                                      () => _registrarSerieRapida(current),
                                  onAjustar:
                                      () => _registrarSerieDetalhada(
                                        current,
                                        numero: current.seriesFeitas + 1,
                                      ),
                                  onConfirmarRestante:
                                      current.series != null &&
                                              current.seriesFeitas <
                                                  current.series!
                                          ? () => _confirmarRestante(current)
                                          : null,
                                  onTrocar:
                                      exercicios.length > 1
                                          ? () => _abrirFila(exercicios)
                                          : null,
                                  onDesfazer:
                                      current.seriesFeitas > 0
                                          ? () => _marcar(
                                            current,
                                            current.seriesFeitas - 1,
                                          )
                                          : null,
                                  onOpenDemo: null,
                                ),
                              ),
                            ),
                  ),
                  if (exercicios.isNotEmpty)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          TokensStrip.s2,
                          TokensStrip.s4,
                          TokensStrip.s3,
                        ),
                        child: SizedBox(
                          height: checkinExecutionControlMin,
                          child:
                              allDone
                                  ? FxLiquidPrimaryButton(
                                    label: checkinFinalizarLabel(),
                                    icon: Icons.flag_rounded,
                                    onPressed: _concluindo ? null : _concluir,
                                    loading: _concluindo,
                                    loadingLabel: 'Finalizando…',
                                  )
                                  : TextButton(
                                    onPressed: _concluindo ? null : _concluir,
                                    style: TextButton.styleFrom(
                                      foregroundColor: chrome.mute,
                                      minimumSize: const Size(
                                        double.infinity,
                                        checkinExecutionControlMin,
                                      ),
                                    ),
                                    child: Text(checkinFinalizarLabel()),
                                  ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
