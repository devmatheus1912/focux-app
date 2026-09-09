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
import '../widgets/checkin_exercise_widgets.dart';
import '../widgets/checkin_execucao_sheets.dart';
import '../widgets/checkin_header_widgets.dart';
import '../widgets/checkin_serie_detail_widgets.dart';
import '../widgets/checkin_timer_widgets.dart';

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
      // Idempotente: mesmo id em retry/double-tap — retoma a execução.
      setState(() {
        _execucao = execucao;
        _loading = false;
      });
      _startedAt =
          execucao.iniciadoEm == null
              ? DateTime.now()
              : DateTime.parse(execucao.iniciadoEm!).toLocal();
      _duration = DateTime.now().difference(_startedAt);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _duration = DateTime.now().difference(_startedAt);
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = friendlyError(e);
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
            title: 'Serie $safeNumero',
            initialCargaKg: serie?.cargaKg ?? ee.cargaKg,
            initialRepeticoes: serie?.repeticoes ?? ee.repeticoes,
            initialFeedback: serie?.feedback ?? ee.feedback,
            initialRpe: serie?.rpe ?? ee.rpe,
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
          title: 'Treino concluido!',
          subtitle: 'Historico atualizado. Continue a sequencia.',
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
    if (_focoTreinoExercicioId != null) {
      for (final e in exercicios) {
        if (e.treinoExercicioId == _focoTreinoExercicioId && !e.concluido) {
          return e;
        }
      }
    }
    return exercicios.firstWhere(
      (e) => !e.concluido,
      orElse: () => exercicios.last,
    );
  }

  Future<void> _sair() async {
    final exercicios = _execucao?.exercicios ?? [];
    final doneSeries = exercicios.fold<int>(
      0,
      (sum, e) => sum + e.seriesFeitas,
    );
    final ok = await fxConfirmLeaveExecution(
      context,
      hasProgress: doneSeries > 0 || _duration.inSeconds > 30,
    );
    if (!ok || !mounted) return;
    safePopOrGo(context, '/checkin/treinos');
  }

  Future<void> _abrirFila(List<ExecucaoExercicio> exercicios) async {
    final picked = await showCheckinFilaSheet(
      context,
      exercicios: exercicios,
      selectedId: _currentExercise(exercicios).treinoExercicioId,
    );
    if (picked == null || !mounted) return;
    setState(() => _focoTreinoExercicioId = picked);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final dark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final brand = dark ? BrandPalette.accent(primary) : primary;
    final mute = chrome.mute;

    if (_loading) {
      return FxExecutionKeepAwake(
        child: fxScreenA11yScope(
        label: 'Checkin',
        child: FxShellScaffold(
          useMesh: false,
          constrainWidth: false,
          body: Padding(
            padding: const EdgeInsets.all(TokensStrip.s4),
            child: Center(
              child: FxLoading.sectionShimmer(
                context,
                height: 180,
                showHeader: false,
              ),
            ),
          ),
        ),
        ),
      );
    }

    if (_loadError != null) {
      return FxExecutionKeepAwake(
        child: fxScreenA11yScope(
        label: 'Checkin',
        child: FxShellScaffold(
          useMesh: false,
          constrainWidth: false,
          body: Center(
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
        ),
      );
    }

    final exercicios = _execucao?.exercicios ?? [];
    final concluidos = exercicios.where((e) => e.concluido).length;
    final current = exercicios.isEmpty ? null : _currentExercise(exercicios);
    final currentIndex = current == null ? 0 : exercicios.indexOf(current) + 1;
    final allDone =
        exercicios.isNotEmpty && exercicios.every((e) => e.concluido);

    return FxExecutionKeepAwake(
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
                  concluido: concluidos,
                  total: exercicios.length,
                ),
                onBack: _sair,
                onHelp:
                    current != null && checkinExerciseHasTips(current)
                        ? () =>
                            showCheckinExerciseTipsSheet(context, ee: current)
                        : null,
              ),
              Expanded(
                child:
                    _showRestTimer
                        ? CheckinRestFocusView(
                          seconds: _restSeconds,
                          onSkip: () {
                            _restTimer?.cancel();
                            setState(() => _showRestTimer = false);
                          },
                        )
                        : exercicios.isEmpty
                        ? const FxEmptyState(
                          icon: 'dumbbell',
                          title: 'Treino sem exercícios',
                          subtitle:
                              'Seu personal ainda não liberou a lista de exercícios deste treino.',
                        )
                        : current == null
                        ? const SizedBox.shrink()
                        : Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: CheckinSerieCard(
                                  ee: current,
                                  index: currentIndex,
                                  total: exercicios.length,
                                  onRegistrar:
                                      () => _registrarSerieDetalhada(
                                        current,
                                        numero: current.seriesFeitas + 1,
                                      ),
                                  onDesfazer:
                                      current.seriesFeitas > 0
                                          ? () => _marcar(
                                            current,
                                            current.seriesFeitas - 1,
                                          )
                                          : null,
                                  onOpenCoach:
                                      () => showCheckinCoachSheet(
                                        context,
                                        ee: current,
                                      ),
                                  onOpenDemo:
                                      checkinExerciseHasDemo(current)
                                          ? () => showCheckinDemoSheet(
                                            context,
                                            ee: current,
                                          )
                                          : null,
                                ),
                              ),
                            ),
                            if (exercicios.length > 1)
                              TextButton(
                                onPressed: () => _abrirFila(exercicios),
                                child: Text(
                                  'Ver fila · ${exercicios.length} exercícios',
                                ),
                              ),
                          ],
                        ),
              ),
              if (exercicios.isNotEmpty && !_showRestTimer)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      TokensStrip.s2,
                      TokensStrip.s4,
                      TokensStrip.s3,
                    ),
                    child:
                        allDone
                            ? SizedBox(
                              height: checkinExecutionControlMin,
                              child: FxLiquidPrimaryButton(
                                label: checkinFinalizarLabel(),
                                icon: Icons.flag_rounded,
                                onPressed: _concluindo ? null : _concluir,
                                loading: _concluindo,
                                loadingLabel: 'Finalizando…',
                              ),
                            )
                            : TextButton(
                              onPressed: _concluindo ? null : _concluir,
                              child: Text(checkinFinalizarLabel()),
                            ),
                  ),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
