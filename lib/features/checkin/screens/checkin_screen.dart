import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      final execucao = await ref.read(checkinRepositoryProvider).iniciar(widget.treinoId);
      setState(() { _execucao = execucao; _loading = false; });
      if (execucao.iniciadoEm != null) {
        final start = DateTime.parse(execucao.iniciadoEm!);
        _duration = DateTime.now().difference(start);
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() { _duration = DateTime.now().difference(start); });
        });
      }
    } catch (e) {
      setState(() { _loading = false; });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'))); context.pop(); }
    }
  }

  Future<void> _marcar(ExecucaoExercicio ee, int seriesFeitas) async {
    if (_execucao == null) return;
    try {
      final updated = await ref.read(checkinRepositoryProvider).marcarExercicio(_execucao!.id!, ee.treinoExercicioId, seriesFeitas);
      setState(() {
        _execucao = ExecucaoTreino(
          id: _execucao!.id, treinoId: _execucao!.treinoId, treinoNome: _execucao!.treinoNome,
          status: _execucao!.status, iniciadoEm: _execucao!.iniciadoEm, concluidoEm: _execucao!.concluidoEm,
          exercicios: _execucao!.exercicios.map((e) => e.id == updated.id ? updated : e).toList(),
        );
      });
      _startRestTimer();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() { _showRestTimer = true; _restSeconds = 60; });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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
    setState(() { _concluindo = true; });
    try {
      await ref.read(checkinRepositoryProvider).concluir(_execucao!.id!);
      ref.invalidate(historicoCheckinProvider);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Treino concluído! 🔥'))); context.pop(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() { _concluindo = false; });
    }
  }

  String _fmt(Duration d) {
    final h = d.inHours; final m = d.inMinutes.remainder(60); final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? EagleTokens.darkBg : EagleTokens.paper;
    final cardBg = dark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;
    final brand = dark ? EagleTokens.brandAccent : EagleTokens.brand;

    final exercicios = _execucao?.exercicios ?? [];
    final concluidos = exercicios.where((e) => e.concluido).length;
    final progresso = exercicios.isEmpty ? 0.0 : concluidos / exercicios.length;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header with giant timer
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: dark
                          ? [const Color(0xFF0A0F1E), EagleTokens.darkBg]
                          : [const Color(0xFFF2F6FF), EagleTokens.paper],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 58, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  color: cardBg, borderRadius: BorderRadius.circular(34),
                                  border: Border.all(color: line),
                                ),
                                child: Icon(Icons.chevron_left, color: ink, size: 20),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('TREINO EM ANDAMENTO', style: TextStyle(color: mute, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                              Text(_execucao?.treinoNome ?? 'Treino', style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w600)),
                            ]),
                          ]),
                          // LIVE badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: dark ? const Color(0x28FF6B6B) : const Color(0xFFFEE4E4),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(children: [
                              _PulseDot(color: const Color(0xFFE64545)),
                              const SizedBox(width: 5),
                              const Text('AO VIVO', style: TextStyle(color: Color(0xFFE64545), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Giant timer
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        RichText(text: TextSpan(
                          children: [
                            TextSpan(
                              text: _fmt(_duration).replaceAll(':', ''),
                              style: TextStyle(color: ink, fontSize: 56, fontWeight: FontWeight.w600, letterSpacing: -2.5, fontFeatures: const [FontFeature.tabularFigures()]),
                            ),
                          ],
                        )),
                        const SizedBox(width: 14),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('decorrido', style: TextStyle(color: mute, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                            Text('est. ${(_duration.inMinutes + 20)} min · ${(progresso * 100).round()}% ✓', style: TextStyle(color: brand, fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progresso, minHeight: 4,
                          backgroundColor: dark ? const Color(0x14FFFFFF) : EagleTokens.brandSoft,
                          valueColor: AlwaysStoppedAnimation(brand),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Exercise list
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _SerieCard(ee: exercicios[i], dark: dark, brand: brand, ink: ink, mute: mute, line: line, cardBg: cardBg, onMarcar: (s) => _marcar(exercicios[i], s)),
                    childCount: exercicios.length,
                  ),
                ),
              ),

              // IA suggestion card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: dark
                            ? const [Color(0xFF1A2852), Color(0xFF0F1A3C)]
                            : [EagleTokens.brand, EagleTokens.brandDeep],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 8),
                          const Text('IA FOCUX · SUGESTÃO AO VIVO', style: TextStyle(color: Color(0xD9FFFFFF), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                        ]),
                        const SizedBox(height: 10),
                        RichText(text: const TextSpan(
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4, color: Colors.white),
                          children: [
                            TextSpan(text: 'Nos últimos 3 treinos o RPE caiu de 8→7. Sugiro '),
                            TextSpan(text: '+2.5kg na próxima série', style: TextStyle(color: Color(0xFFBBD0FF))),
                            TextSpan(text: ' pra manter estímulo.'),
                          ],
                        )),
                        const SizedBox(height: 14),
                        // mini bar chart evidence
                        SizedBox(
                          height: 44,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [8.0, 8.0, 7.5, 7.0, 7.0].asMap().entries.map((e) {
                              final h = (e.value / 8.0) * 36;
                              return Expanded(child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                                  Container(
                                    height: h,
                                    decoration: BoxDecoration(
                                      color: e.key == 4 ? Colors.white : Colors.white38,
                                      borderRadius: BorderRadius.circular(4),
                                      border: e.key == 4 ? Border.all(color: Colors.white, width: 1.5) : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(e.value.toStringAsFixed(0), style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 9, fontWeight: FontWeight.w600)),
                                ]),
                              ));
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: GestureDetector(
                            onTap: () {},
                            child: Container(
                              height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text('Aplicar sugestão', style: TextStyle(color: EagleTokens.brand, fontSize: 13, fontWeight: FontWeight.w700))),
                            ),
                          )),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white30)),
                              child: const Text('Ignorar', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),

              // Finalize button area
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
                  child: GestureDetector(
                    onTap: _concluindo ? null : _concluir,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [brand, EagleTokens.brandInk]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: brand.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Center(
                        child: _concluindo
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('FINALIZAR TREINO', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Floating rest timer
          if (_showRestTimer)
            Positioned(
              left: 16, right: 16, bottom: 88,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xEB12183C) : const Color(0xEB141A2C),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 40, offset: Offset(0, 12))],
                ),
                child: Row(children: [
                  // circular progress
                  SizedBox(
                    width: 44, height: 44,
                    child: Stack(children: [
                      CircularProgressIndicator(
                        value: _restSeconds / 60.0,
                        strokeWidth: 2.5,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF7AD19B)),
                      ),
                      Center(child: Text(
                        '${_restSeconds ~/ 60}:${(_restSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      )),
                    ]),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('DESCANSO', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                    const Text('Próxima série', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ])),
                  GestureDetector(
                    onTap: () { _restTimer?.cancel(); setState(() { _showRestTimer = false; }); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Text('Pular', style: TextStyle(color: EagleTokens.ink, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _ctrl,
    child: Container(width: 6, height: 6, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
  );
}

class _SerieCard extends StatelessWidget {
  final ExecucaoExercicio ee;
  final bool dark;
  final Color brand, ink, mute, line, cardBg;
  final void Function(int) onMarcar;
  const _SerieCard({required this.ee, required this.dark, required this.brand, required this.ink, required this.mute, required this.line, required this.cardBg, required this.onMarcar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ee.concluido ? const Color(0xFF2BB673) : line, width: ee.concluido ? 1.5 : 1),
      ),
      child: ExpansionTile(
        initiallyExpanded: !ee.concluido,
        shape: const Border(),
        tilePadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: ee.concluido ? const Color(0xFF2BB673) : brand.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(ee.concluido ? Icons.check : Icons.fitness_center, color: ee.concluido ? Colors.white : brand, size: 18),
        ),
        title: Text(ee.exercicioNome, style: TextStyle(color: ink, fontWeight: FontWeight.w600, fontSize: 14, decoration: ee.concluido ? TextDecoration.lineThrough : null)),
        subtitle: Text('${ee.series ?? '-'} séries × ${ee.repeticoes ?? '-'} reps', style: TextStyle(color: mute, fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: [
              // Series grid header
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: dark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF0F0EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  for (final label in ['SÉRIE', 'REPS', 'CARGA', 'RPE', ''])
                    Expanded(child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: mute, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                    )),
                ]),
              ),
              const SizedBox(height: 8),
              // Control row
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Séries feitas:', style: TextStyle(color: mute, fontSize: 13, fontWeight: FontWeight.w500)),
                Container(
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF0EFEA),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(children: [
                    IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: ee.seriesFeitas > 0 ? () => onMarcar(ee.seriesFeitas - 1) : null),
                    SizedBox(width: 28, child: Text(ee.seriesFeitas.toString(), textAlign: TextAlign.center, style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()]))),
                    IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => onMarcar(ee.seriesFeitas + 1)),
                  ]),
                ),
              ]),
              if (ee.gifUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(ee.gifUrl!, height: 100, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}
