import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_motion.dart';
import '../data/checkin_repository.dart';
import '../providers/checkin_provider.dart';
import '../../../core/utils/friendly_error.dart';
import 'package:focux_app/core/widgets/fx_empty_state.dart';
import 'package:focux_app/core/widgets/fx_error_state.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

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

class _State extends ConsumerState<ModoPresencialScreen> {
  ExecucaoTreino? _exec;
  bool _loading = true;
  String? _erro;
  int _currentIdx = 0;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  Timer? _restTimer;
  int _restSecs = 0;
  bool _resting = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final e = await ref
          .read(checkinRepositoryProvider)
          .iniciar(widget.treinoId);
      if (!mounted) return;
      setState(() {
        _exec = e;
        _loading = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
        });
      }
    }
  }

  void _startRest(int seconds) {
    setState(() {
      _resting = true;
      _restSecs = seconds;
    });
    HapticFeedback.mediumImpact();
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restSecs <= 1) {
        _restTimer?.cancel();
        HapticFeedback.heavyImpact();
        if (mounted) setState(() => _resting = false);
      } else {
        if (mounted) setState(() => _restSecs--);
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
    } catch (_) {}
  }

  void _next() {
    if (_exec == null) return;
    final max = _exec!.exercicios.length - 1;
    if (_currentIdx < max) setState(() => _currentIdx++);
  }

  void _prev() {
    if (_currentIdx > 0) setState(() => _currentIdx--);
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (_loading) {
      return fxScreenA11yScope(
        label: 'Modo Presencial',
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          body: const SkeletonList(count: 4),
        ),
      );
    }
    if (_erro != null) {
      return fxScreenA11yScope(
        label: 'Modo Presencial',
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          body: FxErrorState(
            chromeOnDark: true,
            primary: primary,
            message: _erro!,
            onRetry: _start,
            title: 'Não conseguimos iniciar o treino',
          ),
        ),
      );
    }
    if (_exec == null || _exec!.exercicios.isEmpty) {
      return fxScreenA11yScope(
        label: 'Modo Presencial',
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          body: FxEmptyState(
            icon: 'dumbbell',
            title: 'Treino não encontrado',
            subtitle:
                'Volte e escolha um treino com exercícios para o modo presencial.',
            action: FxEmptyAction(
              label: 'Voltar',
              onTap: () => Navigator.pop(context),
            ),
          ),
        ),
      );
    }

    final ex = _exec!.exercicios[_currentIdx];
    final total = _exec!.exercicios.length;
    final done = _exec!.exercicios.where((e) => e.concluido).length;

    return fxScreenA11yScope(
      label: 'Modo Presencial',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        body:
            _resting
                ? _restView(primary)
                : _trainingView(ex, total, done, primary),
      ),
    );
  }

  Widget _restView(Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'DESCANSO',
            style: TextStyle(
              color: heroTealMuted(0.54),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: TokensStrip.s4),
          Text(
            '$_restSecs',
            style: TextStyle(
              color: heroTealInk(),
              fontSize: 120,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: TokensStrip.s5),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: _restSecs > 0 ? _restSecs / 60 : 0,
              backgroundColor: Colors.white12,
              color: primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              _restTimer?.cancel();
              setState(() => _resting = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white12,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            child: Text(
              'PULAR',
              style: TextStyle(
                color: heroTealInk(),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
                icon: Icon(Icons.close, color: heroTealMuted(0.54), size: 32),
                onPressed: () => Navigator.pop(context),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: _currentIdx > 0 ? Colors.white : Colors.white24,
                      size: 28,
                    ),
                    onPressed: _currentIdx > 0 ? _prev : null,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color:
                          _currentIdx < total - 1
                              ? Colors.white
                              : Colors.white24,
                      size: 28,
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
                  'EXERCÍCIO ${_currentIdx + 1} DE $total',
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
                  style: TextStyle(
                    color: heroTealInk(),
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: TokensStrip.s4),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.repeat,
                      label: '${ex.series ?? 3} séries',
                    ),
                    const SizedBox(width: 16),
                    _InfoChip(
                      icon: Icons.fitness_center,
                      label: ex.repeticoes ?? '12 reps',
                    ),
                    if (ex.cargaKg != null && ex.cargaKg! > 0) ...[
                      const SizedBox(width: 16),
                      _InfoChip(
                        icon: Icons.monitor_weight,
                        label: '${ex.cargaKg}kg',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: TokensStrip.s5),
                // ── Series progress ──────────────────────────────────
                Row(
                  children: List.generate(ex.series ?? 3, (i) {
                    final isDone = i < ex.seriesFeitas;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDone ? primary : Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child:
                              isDone
                                  ? Icon(
                                    Icons.check,
                                    color: heroTealInk(),
                                    size: 28,
                                  )
                                  : Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: heroTealMuted(0.54),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                        ),
                      ),
                    );
                  }),
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
                  height: 72,
                  child: FxLiquidPrimaryButton(
                    label: 'SÉRIE',
                    icon: Icons.check_rounded,
                    onPressed: () => _completeSerie(ex),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
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
                          'DESCANSO',
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
                Container(
                  padding: const EdgeInsets.all(TokensStrip.s4),
                  decoration: BoxDecoration(
                    color: EagleTokens.good.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: EagleTokens.good,
                        size: 40,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'CONCLUÍDO',
                        style: TextStyle(
                          color: EagleTokens.good,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (_currentIdx < (_exec!.exercicios.length - 1))
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: _next,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'PRÓXIMO',
                          style: TextStyle(color: heroTealMuted(0.54), fontSize: 13),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: heroTealMuted(0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: heroTealMuted(0.54), size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: heroTealMuted(0.70),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
