import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_motion.dart';
import '../data/checkin_repository.dart';
import '../providers/checkin_provider.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import '../../../core/theme/tokens_strip.dart';
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
      if (mounted) setState(() => _loading = false);
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
    if (_loading) {
      return fxScreenA11yScope(
        label: 'Modo Presencial',
        child: Scaffold(
          backgroundColor: EagleTokens.darkBg,
          body: Center(
            child: FxLoading(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      );
    }
    if (_exec == null || _exec!.exercicios.isEmpty) {
      return Scaffold(
        backgroundColor: EagleTokens.darkBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: EagleTokens.darkInkMute,
                size: 48,
              ),
              const SizedBox(height: TokensStrip.s4),
              Text(
                'Treino não encontrado',
                style: TextStyle(color: EagleTokens.darkInkMute, fontSize: 18),
              ),
              const SizedBox(height: TokensStrip.s5),
              FxLiquidPrimaryButton(
                label: 'Voltar',
                onPressed: () => Navigator.pop(context),
                expand: false,
              ),
            ],
          ),
        ),
      );
    }

    final ex = _exec!.exercicios[_currentIdx];
    final total = _exec!.exercicios.length;
    final done = _exec!.exercicios.where((e) => e.concluido).length;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: EagleTokens.darkBg,
      body: SafeArea(
        child:
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
          const Text(
            'DESCANSO',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: TokensStrip.s4),
          Text(
            '$_restSecs',
            style: const TextStyle(
              color: Colors.white,
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
            child: const Text(
              'PULAR',
              style: TextStyle(
                color: Colors.white,
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
          color: Colors.white.withValues(alpha: 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
              Column(
                children: [
                  Text(
                    _fmt(_elapsed),
                    style: const TextStyle(
                      color: Colors.white70,
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
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ex.exercicioNome,
                  style: const TextStyle(
                    color: Colors.white,
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
                                  ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 28,
                                  )
                                  : Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white54,
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
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer, color: Colors.white70, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'DESCANSO',
                          style: TextStyle(
                            color: Colors.white70,
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'PRÓXIMO',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white54,
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
      color: Colors.white12,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
