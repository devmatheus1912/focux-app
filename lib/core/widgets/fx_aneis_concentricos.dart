import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/motion_preferences.dart';

class AnelConcentrico {
  const AnelConcentrico({required this.fracao, required this.cor});

  final double fracao;
  final Color cor;
}

double _contraste(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

/// Três cores da mesma família da marca, com contraste de 3:1 sobre [fundo],
/// em qualquer marca própria.
List<Color> fxCoresDeAnel(Color fundo) {
  final base = HSLColor.fromColor(fundo);
  final escuro = fundo.computeLuminance() < 0.4;
  return [
    for (final giro in const [0.0, 42.0, -42.0])
      () {
        var cor = base
            .withHue((base.hue + giro) % 360)
            .withSaturation(math.max(base.saturation, 0.55))
            .withLightness(escuro ? 0.82 : 0.24);
        while (_contraste(cor.toColor(), fundo) < 3 &&
            cor.lightness > 0.02 &&
            cor.lightness < 0.98) {
          cor = cor.withLightness(
            (cor.lightness + (escuro ? 0.03 : -0.03)).clamp(0.0, 1.0),
          );
        }
        return cor.toColor();
      }(),
  ];
}

/// Até 3 anéis um dentro do outro. Quem usa escreve nome e valor ao lado: arco
/// sozinho não diz o número.
class FxAneisConcentricos extends StatelessWidget {
  const FxAneisConcentricos({
    super.key,
    required this.aneis,
    required this.resumo,
    this.tamanho = 104,
    this.centro,
  });

  final List<AnelConcentrico> aneis;

  /// O que o leitor de tela diz no lugar do desenho.
  final String resumo;
  final double tamanho;
  final Widget? centro;

  @override
  Widget build(BuildContext context) => Semantics(
    label: resumo,
    excludeSemantics: true,
    child: RepaintBoundary(
      child: SizedBox.square(
        dimension: tamanho,
        child: TweenAnimationBuilder<double>(
          // Sobe uma vez, ao abrir; dado novo não repete.
          tween: Tween(begin: 0, end: 1),
          duration: fxMotionDuration(
            context,
            normal: const Duration(milliseconds: 600),
          ),
          curve: Curves.easeOutCubic,
          builder:
              (_, avanco, filho) => CustomPaint(
                painter: _Painter(
                  aneis: aneis,
                  avanco: avanco,
                  espessura: tamanho < 64 ? 5 : 9,
                ),
                child: filho,
              ),
          child: centro == null ? null : Center(child: centro),
        ),
      ),
    ),
  );
}

class _Painter extends CustomPainter {
  const _Painter({
    required this.aneis,
    required this.avanco,
    required this.espessura,
  });

  final List<AnelConcentrico> aneis;
  final double avanco;
  final double espessura;

  @override
  void paint(Canvas canvas, Size size) {
    final vao = espessura * 0.4;
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
        traco..color = anel.cor.withValues(alpha: 0.2),
      );
      final fracao = anel.fracao.clamp(0.0, 1.0) * avanco;
      if (fracao > 0) {
        canvas.drawArc(
          area,
          -math.pi / 2,
          math.pi * 2 * fracao,
          false,
          traco..color = anel.cor,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Painter old) =>
      old.avanco != avanco ||
      old.espessura != espessura ||
      old.aneis != aneis;
}
