import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/fx_aneis_concentricos.dart';
import '../../../core/utils/motion_preferences.dart';
import '../data/meta_corporal.dart';

/// Selo de conquista: anel de traço fino na cor da marca, a mesma linguagem
/// dos anéis do topo da Evolução. A forma diz o tipo:
/// - meta batida: anel fechado com trilha por fora ("fechou o anel");
/// - meta mantida: dois anéis paralelos (ficou na faixa);
/// - recorde: anel aberto embaixo com um traço no topo, o ponteiro no máximo.
///
/// Pequeno, leva um glifo desenhado no mesmo traço (✓, =, ↑); grande, recebe
/// o [miolo] (o número da conquista). Decorativo para leitor de tela: quem
/// usa já lê título e detalhe.
class ConquistaSelo extends StatelessWidget {
  const ConquistaSelo({
    super.key,
    required this.tipo,
    this.tamanho = 40,
    this.miolo,
    this.progresso = 1,
  });

  final ConquistaTipo tipo;
  final double tamanho;

  /// Conteúdo do centro; sem ele, o glifo do tipo.
  final Widget? miolo;

  /// Quanto do anel está desenhado (0 a 1), para a celebração.
  final double progresso;

  /// Traço proporcional: 2,5 em 40, 4 em 120, ~4,7 em 187.
  static double tracoDe(double tamanho) =>
      tamanho <= 40 ? 2.5 : math.min(2.5 + (tamanho - 40) * 0.01875, 4.7);

  /// Cor do traço: a marca, puxada até ter contraste com o fundo (marca clara
  /// sobre fundo claro escurece).
  static Color corDe(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return fxCoresDeAnel(scheme.surface, marca: scheme.primary).first;
  }

  @override
  Widget build(BuildContext context) {
    final cor = corDe(context);
    final miolo = this.miolo;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: tamanho,
        child: CustomPaint(
          painter: _PintorDoSelo(
            tipo: tipo,
            cor: cor,
            traco: tracoDe(tamanho),
            progresso: progresso.clamp(0.0, 1.0),
            glifo: miolo == null,
          ),
          child:
              miolo == null
                  ? null
                  : Padding(
                    padding: EdgeInsets.all(tamanho * 0.2),
                    child: Center(child: miolo),
                  ),
        ),
      ),
    );
  }
}

/// O anel se desenha uma vez (celebração); com Reduzir movimento, pronto.
class ConquistaSeloAnimado extends StatelessWidget {
  const ConquistaSeloAnimado({
    super.key,
    required this.tipo,
    required this.tamanho,
    required this.miolo,
  });

  final ConquistaTipo tipo;
  final double tamanho;
  final Widget miolo;

  @override
  Widget build(BuildContext context) {
    if (fxMotionDurationMs(context) == 0) {
      return ConquistaSelo(tipo: tipo, tamanho: tamanho, miolo: miolo);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      builder:
          (context, t, _) => ConquistaSelo(
            tipo: tipo,
            tamanho: tamanho,
            // 700 ms de anel com easeOutCubic, depois o número em 150 ms.
            progresso: Curves.easeOutCubic.transform((t / 0.82).clamp(0.0, 1.0)),
            miolo: Opacity(
              opacity: ((t - 0.82) / 0.18).clamp(0.0, 1.0),
              child: miolo,
            ),
          ),
    );
  }
}

class _PintorDoSelo extends CustomPainter {
  _PintorDoSelo({
    required this.tipo,
    required this.cor,
    required this.traco,
    required this.progresso,
    required this.glifo,
  });

  final ConquistaTipo tipo;
  final Color cor;
  final double traco;
  final double progresso;
  final bool glifo;

  Paint _pincel(Color c, double largura) =>
      Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = largura
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final raio = size.shortestSide / 2;
    final principal = _pincel(cor, traco);
    final fino = _pincel(cor.withValues(alpha: 0.18), traco);
    const topo = -math.pi / 2;

    void arco(double r, double inicio, double varre, Paint p) => canvas.drawArc(
      Rect.fromCircle(center: centro, radius: r),
      inicio,
      varre,
      false,
      p,
    );

    switch (tipo) {
      case ConquistaTipo.meta:
        final externo = raio - traco / 2;
        final interno = externo - traco * 2.2;
        arco(externo, 0, 2 * math.pi, fino);
        arco(interno, topo, 2 * math.pi * progresso, principal);
      case ConquistaTipo.mantido:
        final externo = raio - traco / 2;
        final interno = externo - traco * 2.6;
        arco(externo, topo, 2 * math.pi * progresso, principal);
        arco(interno, topo, 2 * math.pi * progresso, principal);
      case ConquistaTipo.recorde:
        // 300°, abertura de 60° embaixo, desenhado a partir da esquerda.
        final r = raio - traco / 2 - traco * 1.6;
        const abertura = math.pi / 3;
        arco(r, math.pi / 2 + abertura / 2, (2 * math.pi - abertura) * progresso, principal);
        if (progresso >= 1) {
          // Ponteiro no topo, para fora do anel.
          canvas.drawLine(
            centro.translate(0, -r + traco * 0.2),
            centro.translate(0, -raio + traco / 2),
            principal,
          );
        }
    }

    if (glifo && progresso >= 1) _desenharGlifo(canvas, centro, raio, principal);
  }

  void _desenharGlifo(Canvas canvas, Offset c, double raio, Paint p) {
    final m = raio * 0.32;
    final path = Path();
    switch (tipo) {
      case ConquistaTipo.meta:
        path
          ..moveTo(c.dx - m, c.dy + m * 0.05)
          ..lineTo(c.dx - m * 0.25, c.dy + m * 0.7)
          ..lineTo(c.dx + m, c.dy - m * 0.6);
      case ConquistaTipo.mantido:
        path
          ..moveTo(c.dx - m * 0.8, c.dy - m * 0.35)
          ..lineTo(c.dx + m * 0.8, c.dy - m * 0.35)
          ..moveTo(c.dx - m * 0.8, c.dy + m * 0.35)
          ..lineTo(c.dx + m * 0.8, c.dy + m * 0.35);
      case ConquistaTipo.recorde:
        path
          ..moveTo(c.dx, c.dy + m * 0.85)
          ..lineTo(c.dx, c.dy - m * 0.85)
          ..moveTo(c.dx - m * 0.65, c.dy - m * 0.2)
          ..lineTo(c.dx, c.dy - m * 0.85)
          ..lineTo(c.dx + m * 0.65, c.dy - m * 0.2);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_PintorDoSelo old) =>
      old.tipo != tipo ||
      old.cor != cor ||
      old.traco != traco ||
      old.progresso != progresso ||
      old.glifo != glifo;
}
