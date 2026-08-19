import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../data/checkin_repository.dart';
import '../providers/checkin_provider.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import 'package:focux_app/core/widgets/fx_celebration_overlay.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../widgets/checkin_header_widgets.dart';
import '../widgets/checkin_exercise_widgets.dart';
import '../widgets/checkin_serie_detail_widgets.dart';
import '../widgets/checkin_timer_widgets.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  final int treinoId;
  const CheckinScreen({super.key, required this.treinoId});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  ExecucaoTreino? _execucao;
  bool _loading = true;
  String? _loadError;
  bool _concluindo = false;
  Timer? _timer;
  Duration _duration = Duration.zero;
  bool _showRestTimer = false;
  int _restSeconds = 60;
  int _restTotalSeconds = 60;
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  Future<void> _iniciar() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final execucao = await ref
          .read(checkinRepositoryProvider)
          .iniciar(widget.treinoId);
      if (!mounted) return;
      setState(() {
        _execucao = execucao;
        _loading = false;
      });
      final startedAt =
          execucao.iniciadoEm == null
              ? DateTime.now()
              : DateTime.parse(execucao.iniciadoEm!).toLocal();
      _duration = DateTime.now().difference(startedAt);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _duration = DateTime.now().difference(startedAt);
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = friendlyError(e);
      });
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
      });
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
      });
      if (safeNumero > ee.seriesFeitas) {
        _startRestTimer(ee.descansoSegundos ?? 60);
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _setFeedback(ExecucaoExercicio ee, String value) async {
    if (_execucao == null) return;
    HapticFeedback.selectionClick();
    final selected = ee.feedback == value;
    final nextFeedback = selected ? null : value;
    final nextRpe = selected ? null : _rpeForFeedback(value);
    final nextDor = !selected && value == 'DOR';
    try {
      final updated = await ref
          .read(checkinRepositoryProvider)
          .marcarExercicio(
            _execucao!.id!,
            ee.treinoExercicioId,
            ee.seriesFeitas,
            feedback: nextFeedback,
            rpe: nextRpe,
            dor: nextDor,
          );
      if (!mounted) return;
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
      });
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  int _rpeForFeedback(String value) {
    return switch (value) {
      'FACIL' => 6,
      'OK' => 7,
      'DIFICIL' => 9,
      'DOR' => 10,
      _ => 7,
    };
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _showRestTimer = true;
      _restSeconds = seconds.clamp(15, 600).toInt();
      _restTotalSeconds = _restSeconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_restSeconds <= 0) {
        _restTimer?.cancel();
        setState(() {
          _showRestTimer = false;
        });
      } else {
        setState(() {
          _restSeconds--;
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
      ref.invalidate(historicoCheckinProvider);
      ref.invalidate(meusTreinosProvider);
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
        await _showEvolucaoPerformance(evolucoes);
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

  Future<void> _showEvolucaoPerformance(
    List<EvolucaoPerformance> evolucoes,
  ) async {
    if (!mounted) return;
    final primary = Theme.of(context).colorScheme.primary;
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Evolucao registrada'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Voce evoluiu neste treino. A mensagem tambem ficou salva no chat com seu personal.',
                  ),
                  const SizedBox(height: 14),
                  for (final evolucao in evolucoes.take(4))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            color: primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_labelEvolucao(evolucao.tipo)} em ${evolucao.exercicioNome}: '
                              '${_fmtValor(evolucao.valorAnterior, evolucao.unidade)} -> ${_fmtValor(evolucao.valorAtual, evolucao.unidade)}'
                              '${evolucao.percentual == null ? '' : ' (+${evolucao.percentual}%)'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              FxLiquidPrimaryButton(
                label: 'Continuar',
                onPressed: () => Navigator.pop(ctx),
                expand: false,
              ),
            ],
          ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _labelEvolucao(String tipo) {
    switch (tipo) {
      case 'REPETICOES':
        return 'Repeticoes';
      case 'VOLUME':
        return 'Volume';
      default:
        return 'Carga';
    }
  }

  String _fmtValor(double value, String unidade) {
    final base = _fmtKg(value);
    if (unidade.isEmpty) return base;
    return '$base $unidade';
  }

  String _fmtKg(double value) {
    final fixed = value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 1,
    );
    return fixed.replaceAll('.', ',');
  }

  String _nextExerciseLabel(List<ExecucaoExercicio> exercicios) {
    final next =
        exercicios
            .where((e) => !e.concluido)
            .cast<ExecucaoExercicio?>()
            .firstOrNull;
    return next?.exercicioNome ?? 'Finalizar treino';
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final dark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final brand = dark ? BrandPalette.accent(primary) : primary;
    final brandDeep = BrandPalette.deep(primary);
    final brandSoft = BrandPalette.soft(primary, dark: dark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;

    if (_loading) {
      return fxScreenA11yScope(
        label: 'Checkin',
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(TokensStrip.s4),
              child: SkeletonList(count: 5),
            ),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return fxScreenA11yScope(
        label: 'Checkin',
        child: Scaffold(
          backgroundColor: Colors.transparent,
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
        ),
      );
    }

    final exercicios = _execucao?.exercicios ?? [];
    final concluidos = exercicios.where((e) => e.concluido).length;
    final totalSeries = exercicios.fold<int>(
      0,
      (sum, e) => sum + (e.series ?? 0),
    );
    final doneSeries = exercicios.fold<int>(
      0,
      (sum, e) => sum + e.seriesFeitas,
    );
    final progresso = exercicios.isEmpty ? 0.0 : concluidos / exercicios.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CheckinWorkoutHeader(
                  treinoNome: _execucao?.treinoNome ?? 'Treino',
                  duration: _fmt(_duration),
                  progress: progresso,
                  concluido: concluidos,
                  total: exercicios.length,
                  doneSeries: doneSeries,
                  totalSeries: totalSeries,
                  nextExercise: _nextExerciseLabel(exercicios),
                  brand: brand,
                  brandDeep: brandDeep,
                  brandSoft: brandSoft,
                  ink: ink,
                  mute: mute,
                  line: line,
                  dark: dark,
                  onBack: () => safePopOrGo(context, '/checkin/treinos'),
                ),
              ),
              if (exercicios.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: FxEmptyState(
                    icon: 'dumbbell',
                    title: 'Treino sem exercícios',
                    subtitle:
                        'Seu personal ainda não liberou a lista de exercícios deste treino.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 14, 16, 8),
                  sliver: SliverList.separated(
                    itemCount: exercicios.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final item = exercicios[i];
                      return CheckinSerieCard(
                        ee: item,
                        index: i + 1,
                        total: exercicios.length,
                        dark: dark,
                        brand: brand,
                        ink: ink,
                        mute: mute,
                        line: line,
                        feedback: item.feedback,
                        onFeedback: (value) => _setFeedback(item, value),
                        onMarcar: (s) => _marcar(item, s),
                        onSerieDetalhada:
                            (numero, serie) => _registrarSerieDetalhada(
                              item,
                              numero: numero,
                              serie: serie,
                            ),
                      );
                    },
                  ),
                ),
              if (exercicios.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      2,
                      16,
                      16,
                    ),
                    child: CheckinLiveCoachingCard(
                      brand: brand,
                      brandDeep: brandDeep,
                      dark: dark,
                      onApply: () {
                        FeedbackHelper.showSuccess(
                          context,
                          'Sugestao registrada para a proxima serie.',
                        );
                      },
                      onSkip: () {
                        FeedbackHelper.showSuccess(
                          context,
                          'Sugestao ignorada neste exercicio.',
                        );
                      },
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TokensStrip.s4,
                    0,
                    16,
                    130,
                  ),
                  child: FxLiquidPrimaryButton(
                    label: 'Finalizar treino',
                    icon: Icons.flag_rounded,
                    onPressed: _concluindo ? null : _concluir,
                    loading: _concluindo,
                  ),
                ),
              ),
            ],
          ),
          if (_showRestTimer)
            Positioned(
              left: 0,
              right: 0,
              bottom: 100,
              child: Center(
                child: CheckinRestTimerDock(
                  seconds: _restSeconds,
                  totalSeconds: _restTotalSeconds,
                  brand: brand,
                  dark: dark,
                  ink: ink,
                  mute: mute,
                  line: line,
                  onSkip: () {
                    _restTimer?.cancel();
                    setState(() {
                      _showRestTimer = false;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
