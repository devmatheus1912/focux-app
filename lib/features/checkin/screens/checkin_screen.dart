import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      context.pop();
    }
  }

  Future<void> _marcar(ExecucaoExercicio ee, int seriesFeitas) async {
    if (_execucao == null) return;
    final next = seriesFeitas.clamp(0, ee.series ?? 999);
    final increased = next > ee.seriesFeitas;
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
          exercicios: _execucao!.exercicios
              .map((e) => e.id == updated.id ? updated : e)
              .toList(),
        );
      });
      if (increased) {
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
      await ref.read(checkinRepositoryProvider).concluir(_execucao!.id!);
      ref.invalidate(historicoCheckinProvider);
      ref.invalidate(meusTreinosProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino concluido. Historico atualizado.')),
      );
      context.pop();
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

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
                  onBack: () => context.pop(),
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
  });

  @override
  Widget build(BuildContext context) {
    final targetSeries = ee.series ?? 0;
    final progress = targetSeries == 0 ? 0.0 : (ee.seriesFeitas / targetSeries).clamp(0.0, 1.0);
    final hasMedia = ee.gifUrl?.isNotEmpty == true;
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
                if (hasMedia) ...[
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
                            onPressed: () => onMarcar(ee.seriesFeitas + 1),
                          ),
                        ],
                      ),
                    ),
                  ],
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
