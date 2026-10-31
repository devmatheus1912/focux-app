import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Anel de progresso com o número no meio.
class FxAnel extends StatelessWidget {
  const FxAnel({
    super.key,
    required this.fracao,
    required this.cor,
    required this.fundo,
    required this.child,
    this.tamanho = 88,
  });

  final double fracao;
  final Color cor;
  final Color fundo;
  final Widget child;
  final double tamanho;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: tamanho,
    child: CustomPaint(
      painter: _AnelPainter(fracao: fracao, cor: cor, fundo: fundo),
      child: Center(child: child),
    ),
  );
}

class _AnelPainter extends CustomPainter {
  const _AnelPainter({
    required this.fracao,
    required this.cor,
    required this.fundo,
  });

  final double fracao;
  final Color cor;
  final Color fundo;

  @override
  void paint(Canvas canvas, Size size) {
    const espessura = 8.0;
    final area = (Offset.zero & size).deflate(espessura / 2);
    final traco =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = espessura
          ..strokeCap = StrokeCap.round;
    canvas.drawArc(area, 0, 2 * math.pi, false, traco..color = fundo);
    canvas.drawArc(
      area,
      -math.pi / 2,
      2 * math.pi * fracao.clamp(0.0, 1.0),
      false,
      traco..color = cor,
    );
  }

  @override
  bool shouldRepaint(_AnelPainter old) =>
      old.fracao != fracao || old.cor != cor || old.fundo != fundo;
}
