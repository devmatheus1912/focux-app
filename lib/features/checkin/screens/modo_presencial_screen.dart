import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_execution_chrome.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../data/checkin_repository.dart';
import '../providers/checkin_provider.dart';
import '../utils/checkin_execucao_display.dart';
import '../widgets/checkin_timer_widgets.dart';

/// Landscape-optimized training screen for in-person coaching sessions.
///
/// Features:
/// - Large touch targets for gym use
/// - Auto-landscape orientation lock
/// - Big timer, exercise name, sets/reps counters
/// - Quick-complete buttons per set
/// - Rest timer between sets
class ModoPresencialScreen extends ConsumerStatefulWidget {
  final int treinoId;
  const ModoPresencialScreen({super.key, required this.treinoId});

  @override
  ConsumerState<ModoPresencialScreen> createState() => _State();
}

class _State extends ConsumerState<ModoPresencialScreen>
    with WidgetsBindingObserver {
  ExecucaoTreino? _exec;
  bool _loading = true;
  String? _erro;
  bool _startInFlight = false;
  int _currentIdx = 0;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  DateTime _startedAt = DateTime.now();
  Timer? _restTimer;
  DateTime? _restEndsAt;
  int _restSecs = 0;
  bool _resting = false;

  String get _parent => '/treinos/${widget.treinoId}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _restTimer?.cancel();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncClocks();
  }

  void _syncClocks() {
    if (!mounted) return;
    setState(() {
      _elapsed = DateTime.now().difference(_startedAt);
      if (_resting && _restEndsAt != null) {
        _restSecs = checkinRestRemaining(endsAt: _restEndsAt!);
        if (_restSecs <= 0) {
          _restTimer?.cancel();
          _resting = false;
        }
      }
    });
  }

  Future<void> _start() async {
    if (_startInFlight) return;
    _startInFlight = true;
    try {
      final e = await ref
          .read(checkinRepositoryProvider)
          .iniciar(widget.treinoId);
      if (!mounted) return;
      _elapsed = checkinElapsedSince(e.iniciadoEm);
      _startedAt = DateTime.now().subtract(_elapsed);
      setState(() {
        _exec = e;
        _loading = false;
      });
      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _elapsed = DateTime.now().difference(_startedAt));
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
        });
      }
    } finally {
      _startInFlight = false;
    }
  }

  void _startRest(int seconds) {
    HapticFeedback.mediumImpact();
    _restTimer?.cancel();
    setState(() {
      _resting = true;
      _restEndsAt = DateTime.now().add(Duration(seconds: seconds));
      _restSecs = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _restEndsAt == null) return;
      final left = checkinRestRemaining(endsAt: _restEndsAt!);
      if (left <= 0) {
        _restTimer?.cancel();
        HapticFeedback.heavyImpact();
        setState(() => _resting = false);
      } else {
        setState(() => _restSecs = left);
      }
    });
  }

  Future<void> _completeSerie(ExecucaoExercicio ex) async {
    HapticFeedback.mediumImpact();
    try {
      await ref
          .read(checkinRepositoryProvider)
          .registrarSerie(
            _exec!.id!,
            ex.treinoExercicioId,
            numero: ex.seriesFeitas + 1,
            cargaKg: ex.cargaKg,
            repeticoes: ex.repeticoes,
          );
      await _start();
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  void _next() {
    if (_exec == null) return;
    final max = _exec!.exercicios.length - 1;
    if (_currentIdx < max) setState(() => _currentIdx++);
  }

  void _prev() {
    if (_currentIdx > 0) setState(() => _currentIdx--);
  }

  String _fmt(Duration d) => checkinDurationLabel(d);

  Future<void> _sair() async {
    final doneSeries =
        _exec?.exercicios.fold<int>(0, (sum, e) => sum + e.seriesFeitas) ?? 0;
    final ok = await fxConfirmLeaveExecution(
      context,
      hasProgress: doneSeries > 0 || _elapsed.inSeconds > 30,
    );
    if (!ok || !mounted) return;
    safePopOrGo(context, _parent);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (_loading) {
      return FxExecutionKeepAwake(
        child: fxScreenA11yScope(
          label: 'Modo Presencial',
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
    if (_erro != null) {
      return FxExecutionKeepAwake(
        child: fxScreenA11yScope(
          label: 'Modo Presencial',
          child: FxShellScaffold(
            useMesh: false,
            constrainWidth: false,
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FxErrorState(
                  chromeOnDark: true,
                  primary: primary,
                  message: _erro!,
                  onRetry: _start,
                  title: 'Não conseguimos iniciar o treino',
                ),
                TextButton(
                  onPressed: () => safePopOrGo(context, _parent),
                  child: const Text('Voltar ao treino'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_exec == null || _exec!.exercicios.isEmpty) {
      return FxExecutionKeepAwake(
        child: fxScreenA11yScope(
          label: 'Modo Presencial',
          child: FxShellScaffold(
            useMesh: false,
            constrainWidth: false,
            body: FxEmptyState(
              icon: 'dumbbell',
              title: 'Treino não encontrado',
              subtitle:
                  'Volte e escolha um treino com exercícios para o modo presencial.',
              action: FxEmptyAction(
                label: 'Voltar',
                onTap: () => safePopOrGo(context, _parent),
              ),
            ),
          ),
        ),
      );
    }

    final ex = _exec!.exercicios[_currentIdx];
    final total = _exec!.exercicios.length;
    final done = _exec!.exercicios.where((e) => e.concluido).length;

    return FxExecutionKeepAwake(
      child: FxExecutionPopGuard(
        onLeave: _sair,
        child: fxScreenA11yScope(
          label: 'Modo Presencial',
          child: FxShellScaffold(
            useMesh: false,
            constrainWidth: false,
            body:
                _resting
                    ? CheckinRestFocusView(
                      seconds: _restSecs,
                      onSkip: () {
                        _restTimer?.cancel();
                        setState(() => _resting = false);
                      },
                    )
                    : _trainingView(ex, total, done, primary),
          ),
        ),
      ),
    );
  }

  Widget _trainingView(
    ExecucaoExercicio ex,
    int total,
    int done,
    Color primary,
  ) {
    return Row(
      children: [
        // ── Left: Navigation + Timer ───────────────────────────────
        Container(
          width: 100,
          color: heroTealSurface(0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Sair',
                style: IconButton.styleFrom(
                  minimumSize: const Size(
                    checkinExecutionControlMin,
                    checkinExecutionControlMin,
                  ),
                ),
                icon: Icon(Icons.close, color: heroTealMuted(0.54), size: 28),
                onPressed: _sair,
              ),
              Column(
                children: [
                  Text(
                    _fmt(_elapsed),
                    style: TextStyle(
                      color: heroTealMuted(0.70),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$done/$total',
                    style: TextStyle(
                      color: primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: 'Exercício anterior',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(
                        checkinExecutionControlMin,
                        checkinExecutionControlMin,
                      ),
                    ),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color:
                          _currentIdx > 0
                              ? heroTealInk()
                              : heroTealMuted(0.24),
                      size: 22,
                    ),
                    onPressed: _currentIdx > 0 ? _prev : null,
                  ),
                  IconButton(
                    tooltip: 'Próximo exercício',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(
                        checkinExecutionControlMin,
                        checkinExecutionControlMin,
                      ),
                    ),
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color:
                          _currentIdx < total - 1
                              ? heroTealInk()
                              : heroTealMuted(0.24),
                      size: 22,
                    ),
                    onPressed: _currentIdx < total - 1 ? _next : null,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Center: Exercise info ──────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(TokensStrip.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Exercício ${_currentIdx + 1} de $total',
                  style: TextStyle(
                    color: heroTealMuted(0.38),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ex.exercicioNome,
                  style: FocuxTypography.headline(color: heroTealInk()),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: TokensStrip.s4),
                Text(
                  checkinSerieKpiLabel(ex.seriesFeitas, ex.series),
                  style: FocuxHubTypography.kpi(
                    color: heroTealInk(),
                    fontSize: TokensStrip.fontH1,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: TokensStrip.s2),
                Text(
                  checkinSerieContextLine(
                    seriesReps: checkinSeriesRepsLabel(
                      ex.series,
                      ex.repeticoes,
                    ),
                    carga: checkinCargaLabel(ex.cargaKg),
                    descansoSegundos: ex.descansoSegundos,
                  ),
                  style: FocuxTypography.bodySmall(color: heroTealMuted(0.70)),
                ),
              ],
            ),
          ),
        ),

        // ── Right: Action buttons ──────────────────────────────────
        Container(
          width: 180,
          padding: const EdgeInsets.all(TokensStrip.s4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!ex.concluido) ...[
                SizedBox(
                  width: double.infinity,
                  height: checkinExecutionControlMin,
                  child: FxLiquidPrimaryButton(
                    label: checkinRegistrarLabel(first: ex.seriesFeitas <= 0),
                    icon: Icons.check_rounded,
                    onPressed: () => _completeSerie(ex),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: checkinExecutionControlMin,
                  child: OutlinedButton(
                    onPressed: () => _startRest(ex.descansoSegundos ?? 60),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: heroTealMuted(0.24)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer, color: heroTealMuted(0.70), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Descanso',
                          style: TextStyle(
                            color: heroTealMuted(0.70),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Exercício concluído',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: heroTealMuted(0.70),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (_currentIdx < (_exec!.exercicios.length - 1))
                SizedBox(
                  width: double.infinity,
                  height: checkinExecutionControlMin,
                  child: TextButton(
                    onPressed: _next,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(
                        double.infinity,
                        checkinExecutionControlMin,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Próximo',
                          style: TextStyle(
                            color: heroTealMuted(0.54),
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          color: heroTealMuted(0.54),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
