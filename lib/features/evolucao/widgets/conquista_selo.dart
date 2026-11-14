import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_selo_glifos.dart';
import '../data/meta_corporal.dart';

/// O selo diz o tipo da conquista (a medida está no texto): medalha para meta
/// batida, selo de check para meta mantida, troféu para recorde. Só Phosphor
/// (os desenhos à mão por medida liam como medidor e quebravam o traço).
FxSeloGlifo conquistaGlifo(Conquista c) => switch (c.tipo) {
  ConquistaTipo.meta => FxSeloGlifo.medalha,
  ConquistaTipo.mantido => FxSeloGlifo.verificado,
  ConquistaTipo.recorde => FxSeloGlifo.trofeu,
};

/// Cores do selo saídas da cor da marca (nunca fixas): metal da moldura em
/// três tons, miolo escuro nos dois temas e glifo claro.
typedef ConquistaSeloCores = ({
  Color metalClaro,
  Color metalMedio,
  Color metalEscuro,
  Color miolo,
  Color mioloLuz,
  Color glifo,
});

ConquistaSeloCores conquistaSeloCores(Color marca) {
  final miolo = Color.lerp(marca, Colors.black, 0.78)!;
  return (
    metalClaro: Color.lerp(marca, Colors.white, 0.7)!,
    metalMedio: Color.lerp(marca, Colors.white, 0.25)!,
    metalEscuro: Color.lerp(marca, Colors.black, 0.45)!,
    miolo: miolo,
    mioloLuz: Color.lerp(miolo, marca, 0.35)!,
    glifo: Color.lerp(marca, Colors.white, 0.82)!,
  );
}

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

/// Selo de metal: sombra no chão, moldura em faixas de luz, chanfro claro em
/// cima, miolo afundado e o glifo em leve relevo. Abaixo de [_semDetalheAbaixo]
/// px a sombra interna e o chanfro saem (viram sujeira no tamanho da lista).
class _PintorDoSelo extends CustomPainter {
  _PintorDoSelo({
    required this.cores,
    required this.glifo,
    required this.dupla,
    required this.progresso,
    required this.glifoOpacidade,
  });

  static const _semDetalheAbaixo = 48.0;

  final ConquistaSeloCores cores;
  final FxSeloGlifo glifo;
  final bool dupla;
  final double progresso;
  final double glifoOpacidade;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final raio = size.shortestSide / 2 * 0.94;
    final moldura = math.max(2.0, raio * 0.16);
    final rect = Rect.fromCircle(center: centro, radius: raio);
    final detalhe = size.shortestSide >= _semDetalheAbaixo;
    final externo = seloHexagono(centro, raio);
    final interno = seloHexagono(centro, raio - moldura);

    if (progresso > 0) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: progresso),
      );
      _corpo(canvas, centro, raio, moldura, rect, externo, interno, detalhe);
      canvas.restore();
    }

    // Chanfro: luz na borda de cima, desenhada até [progresso] do contorno.
    if (detalhe) {
      final chanfro =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(0.8, raio * 0.025)
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.7),
                Colors.white.withValues(alpha: 0),
              ],
            ).createShader(rect);
      for (final m in seloHexagono(centro, raio - 0.6).computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * progresso), chanfro);
      }
    }

    if (glifoOpacidade <= 0) return;
    final lado = raio * 0.95;
    final area = Rect.fromCenter(center: centro, width: lado, height: lado);
    // Relevo: o mesmo glifo escuro um pouco abaixo, por baixo do claro.
    fxPintarSeloGlifo(
      canvas,
      glifo,
      area.shift(Offset(0, raio * 0.03)),
      Colors.black.withValues(alpha: 0.5 * glifoOpacidade),
    );
    fxPintarSeloGlifo(
      canvas,
      glifo,
      area,
      cores.glifo.withValues(alpha: glifoOpacidade),
    );
  }

  void _corpo(
    Canvas canvas,
    Offset centro,
    double raio,
    double moldura,
    Rect rect,
    Path externo,
    Path interno,
    bool detalhe,
  ) {
    // Sombra no chão.
    canvas.drawPath(
      seloHexagono(centro + Offset(0, raio * 0.08), raio),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, raio * 0.08),
    );
    // Moldura: metal em faixas, luz em cima à esquerda.
    canvas.drawPath(
      externo,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cores.metalClaro,
            cores.metalMedio,
            cores.metalEscuro,
            cores.metalMedio,
            cores.metalEscuro,
          ],
          stops: const [0, 0.3, 0.55, 0.72, 1],
        ).createShader(rect),
    );
    // Miolo afundado.
    canvas.drawPath(
      interno,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 0.9,
          colors: [cores.mioloLuz, cores.miolo],
        ).createShader(rect),
    );
    if (detalhe) {
      canvas.save();
      canvas.clipPath(interno);
      canvas.drawPath(
        seloHexagono(centro + Offset(0, raio * 0.06), raio - moldura),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = raio * 0.12
          ..color = Colors.black.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, raio * 0.05),
      );
      canvas.restore();
    }
    if (dupla) {
      canvas.drawPath(
        seloHexagono(centro, raio - moldura * 1.9),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, moldura * 0.3)
          ..color = cores.metalClaro.withValues(alpha: 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(_PintorDoSelo old) =>
      old.cores != cores ||
      old.glifo != glifo ||
      old.dupla != dupla ||
      old.progresso != progresso ||
      old.glifoOpacidade != glifoOpacidade;
}
