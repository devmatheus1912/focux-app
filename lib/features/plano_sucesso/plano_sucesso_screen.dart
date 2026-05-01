import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'plano_sucesso_provider.dart';
import 'plano_sucesso_model.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/feedback_helper.dart';

class PlanoSucessoScreen extends StatefulWidget {
  final int alunoId;
  const PlanoSucessoScreen({super.key, required this.alunoId});

  @override
  State<PlanoSucessoScreen> createState() => _PlanoSucessoScreenState();
}

class _PlanoSucessoScreenState extends State<PlanoSucessoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PlanoSucessoProvider>().fetchPlano(widget.alunoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanoSucessoProvider>();

    if (provider.isLoading) {
      return Scaffold(
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? EagleTokens.darkBg
                : EagleTokens.paper,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Plano de Sucesso'),
        ),
        body: const SkeletonList(count: 3),
      );
    }

    final plano = provider.plano;
    if (plano == null) {
      return Scaffold(
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? EagleTokens.darkBg
                : EagleTokens.paper,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Plano de Sucesso'),
        ),
        body: const EmptyStateWidget(
          icon: Icons.flag_outlined,
          title: 'Nenhum Plano Ativo',
          description:
              'Este aluno ainda não possui um plano de sucesso definido pelo personal.',
        ),
      );
    }

    final totalMarcos = plano.marcos.length;
    final marcosConcluidos = plano.marcos.where((m) => m.atingido).length;
    final progresso = totalMarcos == 0 ? 0.0 : marcosConcluidos / totalMarcos;
    final pendentes = plano.marcos.where((m) => !m.atingido).toList();
    final marcoAtual = pendentes.isEmpty ? null : pendentes.first.id;

    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? EagleTokens.darkBg
              : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Plano de Sucesso'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: EagleTokens.heroGradient(
                dark: Theme.of(context).brightness == Brightness.dark,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _SuccessRing(fraction: progresso),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Objetivo: ${plano.objetivoPrincipal}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$marcosConcluidos/$totalMarcos marcos concluidos',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Marcos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...plano.marcos.map(
            (marco) => _MarcoTile(
              marco: marco,
              atual: marcoAtual == marco.id,
              onChanged:
                  marco.atingido
                      ? null
                      : () async {
                        try {
                          await provider.atingirMarco(marco.id);
                          if (!context.mounted) return;
                          FeedbackHelper.showSuccess(
                            context,
                            'Marco atingido! Bom trabalho.',
                          );
                        } catch (_) {
                          if (!context.mounted) return;
                          FeedbackHelper.showError(
                            context,
                            'Erro ao atualizar o marco.',
                          );
                        }
                      },
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessRing extends StatelessWidget {
  final double fraction;
  const _SuccessRing({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(80, 80),
            painter: _SuccessRingPainter(fraction: fraction),
          ),
          Text(
            '${(fraction * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessRingPainter extends CustomPainter {
  final double fraction;
  const _SuccessRingPainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    const r = 32.0;
    final center = Offset(size.width / 2, size.height / 2);
    final track =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.22)
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final active =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, r, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(_SuccessRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}

class _MarcoTile extends StatelessWidget {
  final MarcoSucesso marco;
  final bool atual;
  final VoidCallback? onChanged;

  const _MarcoTile({
    required this.marco,
    required this.atual,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        marco.atingido
            ? EagleTokens.goodSoft
            : (isDark ? EagleTokens.darkCard : EagleTokens.lineSoft);
    final border =
        atual
            ? Theme.of(context).colorScheme.primary
            : (isDark ? EagleTokens.darkLine : EagleTokens.line);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: atual ? 2 : 1),
      ),
      child: CheckboxListTile(
        title: Text(
          marco.titulo,
          style: TextStyle(
            decoration: marco.atingido ? TextDecoration.lineThrough : null,
            fontWeight: atual ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        value: marco.atingido,
        onChanged: onChanged == null ? null : (_) => onChanged!(),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
