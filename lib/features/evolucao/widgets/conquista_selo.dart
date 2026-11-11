import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_selo_glifos.dart';
import '../data/meta_corporal.dart';

/// Glifo de cada conquista (SPEC-selo-conquista). Meta pela métrica;
/// recorde, troféu.
FxSeloGlifo conquistaGlifo(Conquista c) {
  if (c.tipo == ConquistaTipo.recorde) return FxSeloGlifo.trofeu;
  return switch ((c.metrica ?? '').toUpperCase()) {
    'PESO' => FxSeloGlifo.balanca,
    'CINTURA' || 'QUADRIL' => FxSeloGlifo.fitaMetrica,
    'BRACO' => FxSeloGlifo.biceps,
    'GORDURA' => FxSeloGlifo.tronco,
    'MASSA' => FxSeloGlifo.anilhas,
    _ => FxSeloGlifo.trofeu,
  };
}

/// Cores do selo saídas da cor da marca (nunca fixas): moldura em degradê,
/// miolo escuro nos dois temas e glifo claro com brilho.
({Color molduraTopo, Color molduraBase, Color miolo, Color glifo}) conquistaSeloCores(
  Color marca,
) => (
  molduraTopo: Color.lerp(marca, Colors.white, 0.45)!,
  molduraBase: BrandPalette.deep(marca),
  miolo: Color.lerp(marca, Colors.black, 0.78)!,
  glifo: Color.lerp(marca, Colors.white, 0.6)!,
);

/// Selo de conquista: hexágono de pontas arredondadas, moldura metálica na
/// cor da marca, miolo escuro e o glifo aceso. Meta mantida ganha moldura
/// dupla. Decorativo para leitor de tela (o texto ao lado já diz a conquista).
class ConquistaSelo extends StatelessWidget {
  const ConquistaSelo({
    super.key,
    required this.tipo,
    required this.glifo,
    this.tamanho = 40,
    this.progresso = 1,
    this.glifoOpacidade = 1,
    this.marca,
  });

  final ConquistaTipo tipo;
  final FxSeloGlifo glifo;

  /// 40 (lista), 64 (cartão), 160 (celebração).
  final double tamanho;

  /// Quanto da moldura está desenhado (0 a 1), para a celebração.
  final double progresso;
  final double glifoOpacidade;

  /// Cor da marca; sem ela, a primária do tema.
  final Color? marca;

  @override
  Widget build(BuildContext context) {
    final cor = marca ?? Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: tamanho,
        child: CustomPaint(
          painter: _PintorDoSelo(
            cores: conquistaSeloCores(cor),
            glifo: glifo,
            dupla: tipo == ConquistaTipo.mantido,
            progresso: progresso.clamp(0.0, 1.0),
            glifoOpacidade: glifoOpacidade.clamp(0.0, 1.0),
          ),
        ),
      ),
    );
  }
}

/// A moldura se desenha (700 ms), o miolo aparece e o glifo acende (150 ms).
/// Com Reduzir movimento, pronto.
class ConquistaSeloAnimado extends StatelessWidget {
  const ConquistaSeloAnimado({
    super.key,
    required this.tipo,
    required this.glifo,
    required this.tamanho,
    this.marca,
  });

  final ConquistaTipo tipo;
  final FxSeloGlifo glifo;
  final double tamanho;
  final Color? marca;

  @override
  Widget build(BuildContext context) {
    if (fxMotionDurationMs(context) == 0) {
      return ConquistaSelo(tipo: tipo, glifo: glifo, tamanho: tamanho, marca: marca);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      builder:
          (context, t, _) => ConquistaSelo(
            tipo: tipo,
            glifo: glifo,
            tamanho: tamanho,
            marca: marca,
            progresso: Curves.easeOutCubic.transform((t / 0.82).clamp(0.0, 1.0)),
            glifoOpacidade: ((t - 0.82) / 0.18).clamp(0.0, 1.0),
          ),
    );
  }
}

/// Hexágono em pé, de pontas arredondadas.
Path seloHexagono(Offset centro, double raio, {double arredondado = 0.18}) {
  final pontos = [
    for (var i = 0; i < 6; i++)
      centro +
          Offset(
            raio * math.cos(-math.pi / 2 + i * math.pi / 3),
            raio * math.sin(-math.pi / 2 + i * math.pi / 3),
          ),
  ];
  final path = Path();
  final corte = raio * arredondado;
  for (var i = 0; i < 6; i++) {
    final atual = pontos[i];
    final anterior = pontos[(i + 5) % 6];
    final proximo = pontos[(i + 1) % 6];
    final entrada = atual + (anterior - atual) / (anterior - atual).distance * corte;
    final saida = atual + (proximo - atual) / (proximo - atual).distance * corte;
    if (i == 0) {
      path.moveTo(entrada.dx, entrada.dy);
    } else {
      path.lineTo(entrada.dx, entrada.dy);
    }
    path.quadraticBezierTo(atual.dx, atual.dy, saida.dx, saida.dy);
  }
  return path..close();
}

class _PintorDoSelo extends CustomPainter {
  _PintorDoSelo({
    required this.cores,
    required this.glifo,
    required this.dupla,
    required this.progresso,
    required this.glifoOpacidade,
  });

  final ({Color molduraTopo, Color molduraBase, Color miolo, Color glifo}) cores;
  final FxSeloGlifo glifo;
  final bool dupla;
  final double progresso;
  final double glifoOpacidade;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final raio = size.shortestSide / 2;
    final moldura = math.max(1.5, raio * 0.13);
    final externo = seloHexagono(centro, raio - moldura / 2);
    final rect = Offset.zero & size;
    final degrade = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [cores.molduraTopo, cores.molduraBase],
    ).createShader(rect);

    // Miolo escuro (aparece com a moldura).
    canvas.drawPath(
      seloHexagono(centro, raio - moldura),
      Paint()..color = cores.miolo.withValues(alpha: progresso),
    );

    // Moldura: desenhada até [progresso] do contorno.
    final pincel =
        Paint()
          ..shader = degrade
          ..style = PaintingStyle.stroke
          ..strokeWidth = moldura
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round;
    for (final m in externo.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * progresso), pincel);
    }
    if (dupla && progresso >= 1) {
      canvas.drawPath(
        seloHexagono(centro, raio - moldura * 2.2),
        Paint()
          ..color = cores.molduraTopo.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, moldura * 0.35),
      );
    }
    // Brilho curto no canto de cima (o "metal").
    if (progresso >= 1) {
      final brilho =
          Paint()
            ..color = Colors.white.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = moldura * 0.35
            ..strokeCap = StrokeCap.round;
      final a = centro + Offset(-raio * 0.42, -raio * 0.62);
      final b = centro + Offset(-raio * 0.12, -raio * 0.8);
      canvas.drawLine(a, b, brilho);
    }

    if (glifoOpacidade <= 0) return;
    final lado = raio * 0.95;
    final area = Rect.fromCenter(center: centro, width: lado, height: lado);
    final cor = cores.glifo.withValues(alpha: glifoOpacidade);
    // Brilho do glifo: o mesmo desenho, desfocado, por baixo.
    final sigma = math.max(1.0, raio * 0.06);
    canvas.saveLayer(
      rect,
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    );
    fxPintarSeloGlifo(canvas, glifo, area, cor.withValues(alpha: 0.6 * glifoOpacidade));
    canvas.restore();
    fxPintarSeloGlifo(canvas, glifo, area, cor);
  }

  @override
  bool shouldRepaint(_PintorDoSelo old) =>
      old.cores != cores ||
      old.glifo != glifo ||
      old.dupla != dupla ||
      old.progresso != progresso ||
      old.glifoOpacidade != glifoOpacidade;
}

