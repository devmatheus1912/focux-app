import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnelConcentrico {
  const AnelConcentrico({required this.fracao, required this.opacidade});

  final double fracao;
  final double opacidade;
}

/// Até 3 anéis um dentro do outro. Quem usa escreve nome e valor ao lado: arco
/// sozinho não diz o número.
class FxAneisConcentricos extends StatelessWidget {
  const FxAneisConcentricos({
    super.key,
    required this.aneis,
    required this.cor,
    required this.resumo,
    this.tamanho = 104,
  });

  final List<AnelConcentrico> aneis;
  final Color cor;

  /// O que o leitor de tela diz no lugar do desenho.
  final String resumo;
  final double tamanho;

  @override
  Widget build(BuildContext context) => Semantics(
    label: resumo,
    excludeSemantics: true,
    child: SizedBox.square(
      dimension: tamanho,
      child: CustomPaint(painter: _Painter(aneis: aneis, cor: cor)),
    ),
  );
}

class _Painter extends CustomPainter {
  const _Painter({required this.aneis, required this.cor});

  final List<AnelConcentrico> aneis;
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    const espessura = 9.0;
    const vao = 4.0;
    for (final (i, anel) in aneis.indexed) {
      final recuo = espessura / 2 + i * (espessura + vao);
      final area = (Offset.zero & size).deflate(recuo);
      final traco =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = espessura
            ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        area,
        0,
        math.pi * 2,
        false,
        traco..color = cor.withValues(alpha: 0.16),
      );
      final fracao = anel.fracao.clamp(0.0, 1.0);
      if (fracao > 0) {
        canvas.drawArc(
          area,
          -math.pi / 2,
          math.pi * 2 * fracao,
          false,
          traco..color = cor.withValues(alpha: anel.opacidade),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Painter old) => old.aneis != aneis || old.cor != cor;
}
