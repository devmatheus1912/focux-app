import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../data/checkin_repository.dart';
import '../providers/checkin_provider.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  final int treinoId;
  const CheckinScreen({super.key, required this.treinoId});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  ExecucaoTreino? _execucao;
  bool _loading = true;
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
    try {
      final execucao =
          await ref.read(checkinRepositoryProvider).iniciar(widget.treinoId);
      if (!mounted) return;
      setState(() {
        _execucao = execucao;
        _loading = false;
      });
      final startedAt = execucao.iniciadoEm == null
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
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      safePopOrGo(context, '/checkin/treinos');
    }
  }

  Future<void> _marcar(ExecucaoExercicio ee, int seriesFeitas) async {
    if (_execucao == null) return;
    final next = seriesFeitas.clamp(0, ee.series ?? 999);
    try {
      HapticFeedback.selectionClick();
      final updated = await ref.read(checkinRepositoryProvider).marcarExercicio(
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
          exercicios: _execucao!.exercicios
              .map((e) => e.id == updated.id ? updated : e)
              .toList(),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
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
    final payload = await showModalBottomSheet<_SeriePayload>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SerieDetailSheet(
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
      final updated = await ref.read(checkinRepositoryProvider).registrarSerie(
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
          exercicios: _execucao!.exercicios
              .map((e) => e.id == updated.id ? updated : e)
              .toList(),
        );
      });
      if (safeNumero > ee.seriesFeitas) {
        _startRestTimer(ee.descansoSegundos ?? 60);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
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
      final updated = await ref.read(checkinRepositoryProvider).marcarExercicio(
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
          exercicios: _execucao!.exercicios
              .map((e) => e.id == updated.id ? updated : e)
              .toList(),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
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
      final concluida =
          await ref.read(checkinRepositoryProvider).concluir(_execucao!.id!);
      ref.invalidate(historicoCheckinProvider);
      ref.invalidate(meusTreinosProvider);
      if (!mounted) return;
      final evolucoes = concluida.evolucoesPerformance.isNotEmpty
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Treino concluido. Historico atualizado.'),
          ),
        );
      }
      safePopOrGo(context, '/checkin/treinos');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
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
      builder: (ctx) => AlertDialog(
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
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar'),
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
    final fixed = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
    return fixed.replaceAll('.', ',');
  }

  String _nextExerciseLabel(List<ExecucaoExercicio> exercicios) {
    final next = exercicios.where((e) => !e.concluido).cast<ExecucaoExercicio?>().firstOrNull;
    return next?.exercicioNome ?? 'Finalizar treino';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final brand = dark ? BrandPalette.accent(primary) : primary;
    final brandDeep = BrandPalette.deep(primary);
    final brandSoft = BrandPalette.soft(primary, dark: dark);
    final bg = dark ? EagleTokens.darkBg : EagleTokens.paper;
    final cardBg = dark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator(color: brand)),
      );
    }

    final exercicios = _execucao?.exercicios ?? [];
    final concluidos = exercicios.where((e) => e.concluido).length;
    final totalSeries = exercicios.fold<int>(0, (sum, e) => sum + (e.series ?? 0));
    final doneSeries = exercicios.fold<int>(0, (sum, e) => sum + e.seriesFeitas);
    final progresso = exercicios.isEmpty ? 0.0 : concluidos / exercicios.length;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _WorkoutHeader(
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
                  bg: bg,
                  cardBg: cardBg,
                  ink: ink,
                  mute: mute,
                  line: line,
                  dark: dark,
                  onBack: () => safePopOrGo(context, '/checkin/treinos'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                sliver: SliverList.separated(
                  itemCount: exercicios.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final item = exercicios[i];
                    return _SerieCard(
                      ee: item,
                      index: i + 1,
                      total: exercicios.length,
                      dark: dark,
                      brand: brand,
                      ink: ink,
                      mute: mute,
                      line: line,
                      cardBg: cardBg,
                      feedback: item.feedback,
                      onFeedback: (value) => _setFeedback(item, value),
                      onMarcar: (s) => _marcar(item, s),
                      onSerieDetalhada: (numero, serie) => _registrarSerieDetalhada(
                        item,
                        numero: numero,
                        serie: serie,
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                  child: _LiveCoachingCard(
                    brand: brand,
                    brandDeep: brandDeep,
                    dark: dark,
                    onApply: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sugestao registrada para a proxima serie.')),
                      );
                    },
                    onSkip: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sugestao ignorada neste exercicio.')),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
                  child: FilledButton.icon(
                    onPressed: _concluindo ? null : _concluir,
                    icon: _concluindo
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.flag_rounded),
                    label: const Text('Finalizar treino'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: brand,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showRestTimer)
            Positioned(
              left: 16,
              right: 16,
              bottom: 88,
              child: _RestTimerDock(
                seconds: _restSeconds,
                totalSeconds: _restTotalSeconds,
                onSkip: () {
                  _restTimer?.cancel();
                  setState(() {
                    _showRestTimer = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkoutHeader extends StatelessWidget {
  final String treinoNome;
  final String duration;
  final double progress;
  final int concluido;
  final int total;
  final int doneSeries;
  final int totalSeries;
  final String nextExercise;
  final Color brand;
  final Color brandDeep;
  final Color brandSoft;
  final Color bg;
  final Color cardBg;
  final Color ink;
  final Color mute;
  final Color line;
  final bool dark;
  final VoidCallback onBack;

  const _WorkoutHeader({
    required this.treinoNome,
    required this.duration,
    required this.progress,
    required this.concluido,
    required this.total,
    required this.doneSeries,
    required this.totalSeries,
    required this.nextExercise,
    required this.brand,
    required this.brandDeep,
    required this.brandSoft,
    required this.bg,
    required this.cardBg,
    required this.ink,
    required this.mute,
    required this.line,
    required this.dark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark ? [brandDeep, bg] : [brandSoft, bg],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 58, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: line),
                  ),
                  child: Icon(Icons.chevron_left_rounded, color: ink),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TREINO EM ANDAMENTO',
                      style: TextStyle(
                        color: mute,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      treinoNome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: EagleTokens.bad.withValues(alpha: dark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulseDot(color: EagleTokens.bad),
                    const SizedBox(width: 6),
                    const Text(
                      'AO VIVO',
                      style: TextStyle(
                        color: EagleTokens.bad,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            duration,
            style: TextStyle(
              color: ink,
              fontSize: 58,
              fontWeight: FontWeight.w800,
              height: 0.96,
              letterSpacing: -1.0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: dark ? EagleTokens.darkLine : EagleTokens.lineSoft,
              valueColor: AlwaysStoppedAnimation(brand),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  label: 'Exercicios',
                  value: '$concluido/$total',
                  ink: ink,
                  mute: mute,
                  cardBg: cardBg,
                  line: line,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeaderMetric(
                  label: 'Series',
                  value: totalSeries == 0 ? '$doneSeries' : '$doneSeries/$totalSeries',
                  ink: ink,
                  mute: mute,
                  cardBg: cardBg,
                  line: line,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: line),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: brandSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.near_me_rounded, color: brand, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proximo foco',
                        style: TextStyle(
                          color: mute,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextExercise,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color ink;
  final Color mute;
  final Color cardBg;
  final Color line;

  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.ink,
    required this.mute,
    required this.cardBg,
    required this.line,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: mute, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _SerieCard extends StatelessWidget {
  final ExecucaoExercicio ee;
  final int index;
  final int total;
  final bool dark;
  final Color brand;
  final Color ink;
  final Color mute;
  final Color line;
  final Color cardBg;
  final String? feedback;
  final void Function(String) onFeedback;
  final void Function(int) onMarcar;
  final void Function(int, ExecucaoSerie?) onSerieDetalhada;

  const _SerieCard({
    required this.ee,
    required this.index,
    required this.total,
    required this.dark,
    required this.brand,
    required this.ink,
    required this.mute,
    required this.line,
    required this.cardBg,
    required this.feedback,
    required this.onFeedback,
    required this.onMarcar,
    required this.onSerieDetalhada,
  });

  @override
  Widget build(BuildContext context) {
    final targetSeries = ee.series ?? 0;
    final progress = targetSeries == 0 ? 0.0 : (ee.seriesFeitas / targetSeries).clamp(0.0, 1.0);
    final hasMedia = ee.gifUrl?.isNotEmpty == true;
    final hasVideo = ee.videoUrl?.isNotEmpty == true;
    final hasThumbnail = !hasVideo && ee.thumbnailUrl?.isNotEmpty == true;
    final loadText = _formatKg(ee.cargaKg);
    final restText = ee.descansoSegundos == null ? null : '${ee.descansoSegundos}s';
    final hasPrevious = ee.cargaAnteriorKg != null ||
        ee.seriesFeitasAnterior != null ||
        ee.feedbackAnterior != null ||
        ee.rpeAnterior != null;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: ee.concluido ? EagleTokens.good : line,
          width: ee.concluido ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: !ee.concluido,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: ee.concluido
                ? EagleTokens.good.withValues(alpha: 0.12)
                : brand.withValues(alpha: dark ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            ee.concluido ? Icons.check_rounded : Icons.fitness_center_rounded,
            color: ee.concluido ? EagleTokens.good : brand,
            size: 19,
          ),
        ),
        title: Text(
          ee.exercicioNome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            decoration: ee.concluido ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$index/$total  |  ${ee.series ?? '-'} series x ${ee.repeticoes ?? '-'} reps',
            style: TextStyle(color: mute, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasVideo) ...[
                  const SizedBox(height: 4),
                  _ExerciseVideoPreview(url: ee.videoUrl!, brand: brand, dark: dark),
                  const SizedBox(height: 14),
                ] else if (hasThumbnail) ...[
                  const SizedBox(height: 4),
                  _ExerciseThumbnailPreview(
                    url: ee.thumbnailUrl!,
                    videoSource: ee.videoSource,
                    licenseStatus: ee.licenseStatus,
                    brand: brand,
                    dark: dark,
                  ),
                  const SizedBox(height: 14),
                ] else if (hasMedia) ...[
                  const SizedBox(height: 4),
                  _ExerciseMediaPreview(url: ee.gifUrl!, brand: brand, dark: dark),
                  const SizedBox(height: 14),
                ],
                if (loadText != null || restText != null) ...[
                  _ExerciseMetaRow(
                    loadText: loadText,
                    restText: restText,
                    ink: ink,
                    mute: mute,
                    line: line,
                    dark: dark,
                  ),
                  const SizedBox(height: 12),
                ],
                if (ee.observacoes?.trim().isNotEmpty == true) ...[
                  _ExerciseNote(text: ee.observacoes!.trim(), mute: mute, line: line, dark: dark),
                  const SizedBox(height: 12),
                ],
                if (ee.errosComuns?.trim().isNotEmpty == true) ...[
                  _ExecutionGuidanceCard(
                    icon: Icons.report_problem_outlined,
                    title: 'Erros comuns',
                    text: ee.errosComuns!.trim(),
                    color: EagleTokens.warn,
                    ink: ink,
                    line: line,
                    dark: dark,
                  ),
                  const SizedBox(height: 12),
                ],
                if (ee.contraindicacoes?.trim().isNotEmpty == true) ...[
                  _ExecutionGuidanceCard(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Contraindicacoes',
                    text: ee.contraindicacoes!.trim(),
                    color: EagleTokens.bad,
                    ink: ink,
                    line: line,
                    dark: dark,
                  ),
                  const SizedBox(height: 12),
                ],
                if (ee.substitutos?.trim().isNotEmpty == true) ...[
                  _ExecutionGuidanceCard(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Substitutos',
                    text: ee.substitutos!.trim(),
                    color: brand,
                    ink: ink,
                    line: line,
                    dark: dark,
                  ),
                  const SizedBox(height: 12),
                ],
                if (hasPrevious) ...[
                  _PreviousPerformance(
                    loadText: _formatKg(ee.cargaAnteriorKg),
                    seriesText: ee.seriesFeitasAnterior == null ? null : '${ee.seriesFeitasAnterior} series',
                    feedbackText: _formatFeedback(ee.feedbackAnterior, ee.rpeAnterior, ee.dorAnterior),
                    ink: ink,
                    mute: mute,
                    line: line,
                    dark: dark,
                  ),
                  const SizedBox(height: 12),
                ],
                if (ee.seriesDetalhes.isNotEmpty) ...[
                  _SeriesHistory(
                    series: ee.seriesDetalhes,
                    ink: ink,
                    mute: mute,
                    line: line,
                    dark: dark,
                    formatKg: _formatKg,
                    formatFeedback: _formatFeedback,
                    onEdit: (serie) => onSerieDetalhada(serie.numero, serie),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: dark ? EagleTokens.darkLine : EagleTokens.lineSoft,
                          valueColor: AlwaysStoppedAnimation(
                            ee.concluido ? EagleTokens.good : brand,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${ee.seriesFeitas}/${ee.series ?? '-'}',
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Series feitas',
                      style: TextStyle(color: mute, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.06)
                            : EagleTokens.lineSoft,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_rounded, size: 18),
                            onPressed: ee.seriesFeitas > 0 ? () => onMarcar(ee.seriesFeitas - 1) : null,
                          ),
                          SizedBox(
                            width: 30,
                            child: Text(
                              ee.seriesFeitas.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            onPressed: ee.seriesFeitas < targetSeries || targetSeries == 0
                                ? () => onSerieDetalhada(ee.seriesFeitas + 1, null)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: ee.seriesFeitas <= 0
                        ? () => onSerieDetalhada(1, null)
                        : () {
                            final last = ee.seriesDetalhes
                                .where((serie) => serie.numero == ee.seriesFeitas)
                                .cast<ExecucaoSerie?>()
                                .firstOrNull;
                            onSerieDetalhada(ee.seriesFeitas, last);
                          },
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: Text(ee.seriesFeitas <= 0 ? 'Registrar serie detalhada' : 'Editar ultima serie'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brand,
                      side: BorderSide(color: brand.withValues(alpha: 0.45)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Como foi?',
                  style: TextStyle(color: mute, fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FeedbackChip(label: 'Facil', selected: feedback == 'FACIL', color: brand, onTap: () => onFeedback('FACIL')),
                    _FeedbackChip(label: 'Ok', selected: feedback == 'OK', color: brand, onTap: () => onFeedback('OK')),
                    _FeedbackChip(label: 'Dificil', selected: feedback == 'DIFICIL', color: brand, onTap: () => onFeedback('DIFICIL')),
                    _FeedbackChip(label: 'Dor', selected: feedback == 'DOR', color: EagleTokens.bad, onTap: () => onFeedback('DOR')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _formatKg(double? value) {
    if (value == null) return null;
    final rounded = value.roundToDouble() == value ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return '$rounded kg';
  }

  String? _formatFeedback(String? feedback, int? rpe, bool? dor) {
    final labels = {
      'FACIL': 'Facil',
      'OK': 'Ok',
      'DIFICIL': 'Dificil',
      'DOR': 'Dor',
    };
    final parts = <String>[
      if (feedback != null) labels[feedback] ?? feedback,
      if (rpe != null) 'RPE $rpe',
      if (dor == true && feedback != 'DOR') 'Dor',
    ];
    return parts.isEmpty ? null : parts.join(' | ');
  }
}

class _ExerciseMetaRow extends StatelessWidget {
  final String? loadText;
  final String? restText;
  final Color ink;
  final Color mute;
  final Color line;
  final bool dark;

  const _ExerciseMetaRow({
    required this.loadText,
    required this.restText,
    required this.ink,
    required this.mute,
    required this.line,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (loadText != null)
          _TinyMetric(icon: Icons.scale_rounded, label: 'Carga', value: loadText!, ink: ink, mute: mute, line: line, dark: dark),
        if (restText != null)
          _TinyMetric(icon: Icons.timer_rounded, label: 'Descanso', value: restText!, ink: ink, mute: mute, line: line, dark: dark),
      ],
    );
  }
}

class _ExerciseNote extends StatelessWidget {
  final String text;
  final Color mute;
  final Color line;
  final bool dark;

  const _ExerciseNote({
    required this.text,
    required this.mute,
    required this.line,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.05) : EagleTokens.lineSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      ),
      child: Text(
        text,
        style: TextStyle(color: mute, fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.35),
      ),
    );
  }
}

class _ExecutionGuidanceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  final Color ink;
  final Color line;
  final bool dark;

  const _ExecutionGuidanceCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
    required this.ink,
    required this.line,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: ink, fontSize: 12.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(text, style: TextStyle(color: ink.withValues(alpha: 0.82), fontSize: 12.3, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviousPerformance extends StatelessWidget {
  final String? loadText;
  final String? seriesText;
  final String? feedbackText;
  final Color ink;
  final Color mute;
  final Color line;
  final bool dark;

  const _PreviousPerformance({
    required this.loadText,
    required this.seriesText,
    required this.feedbackText,
    required this.ink,
    required this.mute,
    required this.line,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final details = [
      if (seriesText != null) seriesText!,
      if (loadText != null) loadText!,
      if (feedbackText != null) feedbackText!,
    ].join(' | ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF10243C) : const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 18, color: dark ? Colors.white70 : EagleTokens.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ultima execucao', style: TextStyle(color: mute, fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(details, style: TextStyle(color: ink, fontSize: 12.5, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesHistory extends StatelessWidget {
  final List<ExecucaoSerie> series;
  final Color ink;
  final Color mute;
  final Color line;
  final bool dark;
  final String? Function(double?) formatKg;
  final String? Function(String?, int?, bool?) formatFeedback;
  final void Function(ExecucaoSerie) onEdit;

  const _SeriesHistory({
    required this.series,
    required this.ink,
    required this.mute,
    required this.line,
    required this.dark,
    required this.formatKg,
    required this.formatFeedback,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Series registradas', style: TextStyle(color: mute, fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...series.map((serie) {
            final details = [
              if (serie.repeticoes?.isNotEmpty == true) serie.repeticoes!,
              if (formatKg(serie.cargaKg) != null) formatKg(serie.cargaKg)!,
              if (formatFeedback(serie.feedback, serie.rpe, serie.dor) != null)
                formatFeedback(serie.feedback, serie.rpe, serie.dor)!,
            ].join(' | ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: EagleTokens.good.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      serie.numero.toString(),
                      style: const TextStyle(color: EagleTokens.good, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      details.isEmpty ? 'Serie registrada' : details,
                      style: TextStyle(color: ink, fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Editar serie',
                    icon: Icon(Icons.edit_rounded, size: 17, color: mute),
                    onPressed: () => onEdit(serie),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SeriePayload {
  final double? cargaKg;
  final String? repeticoes;
  final String? feedback;
  final int? rpe;
  final bool dor;

  const _SeriePayload({
    required this.cargaKg,
    required this.repeticoes,
    required this.feedback,
    required this.rpe,
    required this.dor,
  });
}

class _SerieDetailSheet extends StatefulWidget {
  final String title;
  final double? initialCargaKg;
  final String? initialRepeticoes;
  final String? initialFeedback;
  final int? initialRpe;
  final bool initialDor;

  const _SerieDetailSheet({
    required this.title,
    required this.initialCargaKg,
    required this.initialRepeticoes,
    required this.initialFeedback,
    required this.initialRpe,
    required this.initialDor,
  });

  @override
  State<_SerieDetailSheet> createState() => _SerieDetailSheetState();
}

class _SerieDetailSheetState extends State<_SerieDetailSheet> {
  late final TextEditingController _cargaController;
  late final TextEditingController _repsController;
  late String? _feedback;
  late int _rpe;
  late bool _useRpe;
  late bool _dor;

  @override
  void initState() {
    super.initState();
    _cargaController = TextEditingController(text: _formatInitialKg(widget.initialCargaKg));
    _repsController = TextEditingController(text: widget.initialRepeticoes ?? '');
    _feedback = widget.initialFeedback;
    _rpe = widget.initialRpe ?? 7;
    _useRpe = widget.initialRpe != null;
    _dor = widget.initialDor;
  }

  @override
  void dispose() {
    _cargaController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final brand = dark ? BrandPalette.accent(primary) : primary;
    final bg = dark ? EagleTokens.darkCard : Colors.white;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: line)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: mute.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    icon: Icon(Icons.close_rounded, color: mute),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SerieField(
                      controller: _cargaController,
                      label: 'Carga',
                      suffix: 'kg',
                      icon: Icons.scale_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
                      ink: ink,
                      mute: mute,
                      line: line,
                      dark: dark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SerieField(
                      controller: _repsController,
                      label: 'Reps',
                      suffix: 'x',
                      icon: Icons.repeat_rounded,
                      keyboardType: TextInputType.text,
                      ink: ink,
                      mute: mute,
                      line: line,
                      dark: dark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Sensacao', style: TextStyle(color: mute, fontSize: 12, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FeedbackChip(label: 'Facil', selected: _feedback == 'FACIL', color: brand, onTap: () => _toggleFeedback('FACIL')),
                  _FeedbackChip(label: 'Ok', selected: _feedback == 'OK', color: brand, onTap: () => _toggleFeedback('OK')),
                  _FeedbackChip(label: 'Dificil', selected: _feedback == 'DIFICIL', color: brand, onTap: () => _toggleFeedback('DIFICIL')),
                  _FeedbackChip(label: 'Dor', selected: _feedback == 'DOR', color: EagleTokens.bad, onTap: () => _toggleFeedback('DOR')),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dark ? Colors.white.withValues(alpha: 0.05) : EagleTokens.lineSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: line),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('RPE ${_useRpe ? _rpe : "-"}', style: TextStyle(color: ink, fontWeight: FontWeight.w900)),
                        ),
                        Switch.adaptive(
                          value: _useRpe,
                          activeColor: brand,
                          onChanged: (value) => setState(() => _useRpe = value),
                        ),
                      ],
                    ),
                    Slider(
                      value: _rpe.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: brand,
                      label: 'RPE $_rpe',
                      onChanged: _useRpe ? (value) => setState(() => _rpe = value.round()) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeColor: EagleTokens.bad,
                value: _dor,
                onChanged: (value) => setState(() {
                  _dor = value;
                  if (value) {
                    _feedback = 'DOR';
                    _useRpe = true;
                    _rpe = _rpe < 8 ? 8 : _rpe;
                  }
                }),
                title: Text('Senti dor nesta serie', style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
                subtitle: Text('Marca alerta para o personal acompanhar.', style: TextStyle(color: mute, fontSize: 12)),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Salvar serie'),
                  style: FilledButton.styleFrom(
                    backgroundColor: brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFeedback(String value) {
    setState(() {
      _feedback = _feedback == value ? null : value;
      if (_feedback == 'DOR') {
        _dor = true;
        _useRpe = true;
        _rpe = _rpe < 8 ? 8 : _rpe;
      }
    });
  }

  void _submit() {
    Navigator.pop(
      context,
      _SeriePayload(
        cargaKg: _parseKg(_cargaController.text),
        repeticoes: _blankToNull(_repsController.text),
        feedback: _feedback,
        rpe: _useRpe ? _rpe : null,
        dor: _dor,
      ),
    );
  }

  String _formatInitialKg(double? value) {
    if (value == null) return '';
    return value.roundToDouble() == value ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  double? _parseKg(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _SerieField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Color ink;
  final Color mute;
  final Color line;
  final bool dark;

  const _SerieField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
    required this.keyboardType,
    this.inputFormatters,
    required this.ink,
    required this.mute,
    required this.line,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: ink, fontWeight: FontWeight.w900),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: mute, fontWeight: FontWeight.w700),
        suffixText: suffix,
        suffixStyle: TextStyle(color: mute, fontWeight: FontWeight.w800),
        prefixIcon: Icon(icon, color: mute, size: 18),
        filled: true,
        fillColor: dark ? Colors.white.withValues(alpha: 0.05) : EagleTokens.lineSoft,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _TinyMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color ink;
  final Color mute;
  final Color line;
  final bool dark;

  const _TinyMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.ink,
    required this.mute,
    required this.line,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: mute),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(color: mute, fontSize: 11.5, fontWeight: FontWeight.w800)),
          Text(value, style: TextStyle(color: ink, fontSize: 11.5, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ExerciseThumbnailPreview extends StatelessWidget {
  final String url;
  final String? videoSource;
  final String? licenseStatus;
  final Color brand;
  final bool dark;

  const _ExerciseThumbnailPreview({
    required this.url,
    required this.videoSource,
    required this.licenseStatus,
    required this.brand,
    required this.dark,
  });

  String _badgeLabel() {
    if (licenseStatus == 'LICENSED') return 'Video licenciado';
    if (videoSource == 'PERSONAL_UPLOAD') return 'Video do personal';
    if (videoSource == 'FOCUX_LIBRARY') return 'Biblioteca Focux';
    return 'Tecnica do exercicio';
  }

  IconData _badgeIcon() {
    if (licenseStatus == 'LICENSED') return Icons.verified_rounded;
    if (videoSource == 'PERSONAL_UPLOAD') return Icons.person_rounded;
    return Icons.play_arrow_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Image.network(
            url,
            height: 168,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              color: dark ? EagleTokens.darkCardHi : EagleTokens.lineSoft,
              alignment: Alignment.center,
              child: Icon(Icons.play_circle_outline_rounded, color: brand),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_badgeIcon(), color: Colors.white, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    _badgeLabel(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseMediaPreview extends StatelessWidget {
  final String url;
  final Color brand;
  final bool dark;

  const _ExerciseMediaPreview({
    required this.url,
    required this.brand,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Image.network(
            url,
            height: 168,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              color: dark ? EagleTokens.darkCardHi : EagleTokens.lineSoft,
              alignment: Alignment.center,
              child: Icon(Icons.play_circle_outline_rounded, color: brand),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.42),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Tecnica do exercicio',
                    style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseVideoPreview extends StatefulWidget {
  final String url;
  final Color brand;
  final bool dark;

  const _ExerciseVideoPreview({
    required this.url,
    required this.brand,
    required this.dark,
  });

  @override
  State<_ExerciseVideoPreview> createState() => _ExerciseVideoPreviewState();
}

class _ExerciseVideoPreviewState extends State<_ExerciseVideoPreview> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        _controller.setLooping(true);
        setState(() => _ready = true);
      }).catchError((_) {
        if (mounted) setState(() => _failed = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return _VideoFallback(brand: widget.brand, dark: widget.dark);
    }
    if (!_ready) {
      return Container(
        height: 168,
        width: double.infinity,
        decoration: BoxDecoration(
          color: widget.dark ? EagleTokens.darkCardHi : EagleTokens.lineSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: widget.brand.withValues(alpha: 0.22)),
        ),
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: widget.brand, strokeWidth: 2.5),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio == 0 ? 16 / 9 : _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.46),
                  ],
                ),
              ),
            ),
          ),
          IconButton.filled(
            onPressed: () {
              setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller.play();
              });
            },
            icon: Icon(_controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.46),
              foregroundColor: Colors.white,
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, color: Colors.white, size: 15),
                  SizedBox(width: 5),
                  Text(
                    'Video do personal',
                    style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoFallback extends StatelessWidget {
  final Color brand;
  final bool dark;

  const _VideoFallback({
    required this.brand,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark ? EagleTokens.darkCardHi : EagleTokens.lineSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brand.withValues(alpha: 0.26)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_fill_rounded, color: brand, size: 34),
          const SizedBox(height: 6),
          Text(
            'Video proprio do personal disponivel',
            style: TextStyle(color: brand, fontSize: 12.5, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _FeedbackChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FeedbackChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: selected ? 0.0 : 0.22)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LiveCoachingCard extends StatelessWidget {
  final Color brand;
  final Color brandDeep;
  final bool dark;
  final VoidCallback onApply;
  final VoidCallback onSkip;

  const _LiveCoachingCard({
    required this.brand,
    required this.brandDeep,
    required this.dark,
    required this.onApply,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark ? [brandDeep, const Color(0xFF0F1A3C)] : [brand, brandDeep],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15),
              ),
              const SizedBox(width: 8),
              const Text(
                'IA FOCUX | SUGESTAO AO VIVO',
                style: TextStyle(
                  color: Color(0xD9FFFFFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Se a proxima serie ficar facil, registre o feedback. Isso ajuda o personal a ajustar carga, volume e descanso com mais precisao.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.42,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: brand,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Registrar ajuste'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onSkip,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.32)),
                  minimumSize: const Size(92, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Ignorar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestTimerDock extends StatelessWidget {
  final int seconds;
  final int totalSeconds;
  final VoidCallback onSkip;

  const _RestTimerDock({
    required this.seconds,
    required this.totalSeconds,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xEB141A2C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 40, offset: Offset(0, 12)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: totalSeconds <= 0 ? 0 : seconds / totalSeconds,
                  strokeWidth: 3,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF7AD19B)),
                ),
                Center(
                  child: Text(
                    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DESCANSO',
                  style: TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Respira e prepara a proxima serie',
                  style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Pular'),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
