import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../data/checkin_repository.dart';
import '../providers/checkin_provider.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import 'package:focux_app/core/widgets/fx_celebration_overlay.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
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
  int? _focoTreinoExercicioId;

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
      _applyUpdated(updated);
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
    await showFxNoticeSheet(
      context,
      title: 'Evolucao registrada',
      icon: Icons.trending_up_rounded,
      actionLabel: 'Continuar',
      message:
          'Voce evoluiu neste treino. A mensagem tambem ficou salva no chat com seu personal.',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final evolucao in evolucoes.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.trending_up_rounded, color: primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_labelEvolucao(evolucao.tipo)} em ${evolucao.exercicioNome}: '
                      '${_fmtValor(evolucao.valorAnterior, evolucao.unidade)} -> ${_fmtValor(evolucao.valorAtual, evolucao.unidade)}'
                      '${evolucao.percentual == null ? '' : ' (+${evolucao.percentual}%)'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
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
    final doneSeries = exercicios.fold<int>(0, (sum, e) => sum + e.seriesFeitas);
    if (doneSeries > 0 || _duration.inSeconds > 30) {
      final ok = await showFxConfirmSheet(
        context,
        title: 'Sair do treino?',
        message: 'O tempo e as séries já marcadas ficam salvos.',
        confirmLabel: 'Sair',
      );
      if (!ok || !mounted) return;
    }
    safePopOrGo(context, '/checkin/treinos');
  }

  Future<void> _abrirFila(List<ExecucaoExercicio> exercicios) async {
    final picked = await showFxHomeSheet<int>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return FxHomeSheetSurface(
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              const SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: isDark,
                title: 'Fila do treino',
                subtitle: '${exercicios.length} exercícios',
                leading: const Icon(Icons.format_list_numbered_rounded, size: 18),
              ),
              const SizedBox(height: TokensStrip.s3),
              for (final item in exercicios)
                ListTile(
                  title: Text(item.exercicioNome),
                  subtitle: Text(
                    item.concluido
                        ? 'Concluído'
                        : '${item.seriesFeitas}/${item.series ?? 0} séries',
                  ),
                  onTap: () => Navigator.of(ctx).pop(item.treinoExercicioId),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _focoTreinoExercicioId = picked);
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
        child: FxShellScaffold(
          useMesh: false,
          constrainWidth: false,
          body: const Padding(
            padding: EdgeInsets.all(TokensStrip.s4),
            child: SkeletonList(count: 5),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return fxScreenA11yScope(
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
    final current = exercicios.isEmpty ? null : _currentExercise(exercicios);
    final currentIndex =
        current == null ? 0 : exercicios.indexOf(current) + 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _sair();
      },
      child: fxScreenA11yScope(
        label: 'Checkin',
        child: FxShellScaffold(
          useMesh: false,
          constrainWidth: false,
          safeArea: false,
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
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
                            onBack: _sair,
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
                        else if (current != null)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              TokensStrip.s4,
                              14,
                              16,
                              8,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  CheckinSerieCard(
                                    ee: current,
                                    index: currentIndex,
                                    total: exercicios.length,
                                    dark: dark,
                                    brand: brand,
                                    ink: ink,
                                    mute: mute,
                                    line: line,
                                    feedback: current.feedback,
                                    onFeedback:
                                        (value) => _setFeedback(current, value),
                                    onMarcar: (s) => _marcar(current, s),
                                    onSerieDetalhada:
                                        (numero, serie) =>
                                            _registrarSerieDetalhada(
                                              current,
                                              numero: numero,
                                              serie: serie,
                                            ),
                                  ),
                                  if (exercicios.length > 1)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton(
                                        onPressed: () => _abrirFila(exercicios),
                                        child: Text(
                                          'Ver fila · ${exercicios.length} exercícios',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (exercicios.isNotEmpty)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          TokensStrip.s2,
                          16,
                          TokensStrip.s3,
                        ),
                        child: SizedBox(
                          height: 64,
                          child: FxLiquidPrimaryButton(
                            label: 'Finalizar treino',
                            icon: Icons.flag_rounded,
                            onPressed: _concluindo ? null : _concluir,
                            loading: _concluindo,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (_showRestTimer)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 88,
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
        ),
      ),
    );
  }
}
