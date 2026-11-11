import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/fx_icons.dart';

/// Glifos do selo de conquista (kit de 13). Os que existem no Phosphor saem
/// do [FxIcons]; os outros são traço desenhado na grade de 24, no mesmo peso
/// do Phosphor Light (1,5), pontas e cantos arredondados. Só existem dentro do
/// selo: ícone solto continua sendo [FxIcons].
enum FxSeloGlifo {
  balanca,
  fitaMetrica,
  anilhas,
  halteresCruzados,
  halter,
  biceps,
  tronco,
  setasCima,
  trofeu,
  coroa,
  brilhos,
  barra,
  grafico,
}

/// Ícone do Phosphor para o glifo, quando há.
IconData? fxSeloGlifoPhosphor(FxSeloGlifo g) => switch (g) {
  FxSeloGlifo.fitaMetrica => FxIcons.fitaMetrica,
  FxSeloGlifo.trofeu => FxIcons.trofeu,
  FxSeloGlifo.coroa => FxIcons.premium,
  FxSeloGlifo.brilhos => FxIcons.ia,
  FxSeloGlifo.barra => FxIcons.treino,
  FxSeloGlifo.grafico => FxIcons.grafico,
  _ => null,
};

/// Desenha [glifo] centrado em [area] (quadrada) com traço [cor].
void fxPintarSeloGlifo(Canvas canvas, FxSeloGlifo glifo, Rect area, Color cor) {
  final icone = fxSeloGlifoPhosphor(glifo);
  if (icone != null) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icone.codePoint),
        style: TextStyle(
          fontFamily: icone.fontFamily,
          package: icone.fontPackage,
          fontSize: area.width,
          color: cor,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      area.center - Offset(tp.width / 2, tp.height / 2),
    );
    return;
  }
  final u = area.width / 24;
  final o = area.topLeft;
  Offset p(double x, double y) => o + Offset(x * u, y * u);
  final pincel =
      Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * u
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
  final path = Path();
  void rrect(double l, double t, double r, double b, double raio) => path.addRRect(
    RRect.fromRectAndRadius(Rect.fromPoints(p(l, t), p(r, b)), Radius.circular(raio * u)),
  );
  void linha(double x1, double y1, double x2, double y2) {
    path
      ..moveTo(p(x1, y1).dx, p(x1, y1).dy)
      ..lineTo(p(x2, y2).dx, p(x2, y2).dy);
  }

  switch (glifo) {
    case FxSeloGlifo.balanca:
      // Balança de banheiro: corpo arredondado e o mostrador com ponteiro.
      rrect(4, 4, 20, 20, 3);
      path.addArc(Rect.fromCircle(center: p(12, 11), radius: 4 * u), math.pi, math.pi);
      linha(12, 11, 13.6, 8.6);
    case FxSeloGlifo.anilhas:
      // Três anilhas empilhadas, da maior para a menor.
      rrect(4, 16, 20, 19.5, 1.5);
      rrect(5.5, 11.5, 18.5, 15, 1.5);
      rrect(7, 7, 17, 10.5, 1.5);
      linha(12, 4, 12, 7);
    case FxSeloGlifo.halteresCruzados:
      _halter(path, p, u, angulo: math.pi / 4);
      _halter(path, p, u, angulo: -math.pi / 4);
    case FxSeloGlifo.halter:
      _halter(path, p, u, angulo: 0);
    case FxSeloGlifo.biceps:
      // Braço flexionado em linha: antebraço, cotovelo e o bíceps.
      path
        ..moveTo(p(5, 19).dx, p(5, 19).dy)
        ..quadraticBezierTo(p(9, 20).dx, p(9, 20).dy, p(14, 18).dx, p(14, 18).dy)
        ..quadraticBezierTo(p(19.5, 15.5).dx, p(19.5, 15.5).dy, p(18, 10).dx, p(18, 10).dy)
        ..quadraticBezierTo(p(17, 6.5).dx, p(17, 6.5).dy, p(14, 5).dx, p(14, 5).dy)
        ..lineTo(p(12, 7).dx, p(12, 7).dy)
        ..lineTo(p(14.5, 9).dx, p(14.5, 9).dy)
        ..quadraticBezierTo(p(13, 13).dx, p(13, 13).dy, p(9, 14).dx, p(9, 14).dy)
        ..quadraticBezierTo(p(6, 14.5).dx, p(6, 14.5).dy, p(5, 19).dx, p(5, 19).dy);
    case FxSeloGlifo.tronco:
      // Tronco: ombros, cintura e a linha do abdômen.
      path
        ..moveTo(p(5, 6).dx, p(5, 6).dy)
        ..quadraticBezierTo(p(12, 3.5).dx, p(12, 3.5).dy, p(19, 6).dx, p(19, 6).dy)
        ..quadraticBezierTo(p(17, 13).dx, p(17, 13).dy, p(16, 20).dx, p(16, 20).dy)
        ..lineTo(p(8, 20).dx, p(8, 20).dy)
        ..quadraticBezierTo(p(7, 13).dx, p(7, 13).dy, p(5, 6).dx, p(5, 6).dy);
      linha(12, 9, 12, 17);
      linha(9.5, 12, 14.5, 12);
    case FxSeloGlifo.setasCima:
      // Duas setas para cima, a da frente mais alta.
      linha(9, 20, 9, 9);
      linha(5.5, 12.5, 9, 9);
      linha(9, 9, 12.5, 12.5);
      linha(15, 20, 15, 5);
      linha(11.5, 8.5, 15, 5);
      linha(15, 5, 18.5, 8.5);
    case FxSeloGlifo.fitaMetrica:
    case FxSeloGlifo.trofeu:
    case FxSeloGlifo.coroa:
    case FxSeloGlifo.brilhos:
    case FxSeloGlifo.barra:
    case FxSeloGlifo.grafico:
      break; // Phosphor, desenhados acima.
  }
  canvas.drawPath(path, pincel);
}

/// Halter girado em [angulo] em volta do centro da grade.
void _halter(
  Path path,
  Offset Function(double, double) p,
  double u, {
  required double angulo,
}) {
  final centro = p(12, 12);
  Offset r(double x, double y) {
    final v = p(x, y) - centro;
    return centro +
        Offset(
          v.dx * math.cos(angulo) - v.dy * math.sin(angulo),
          v.dx * math.sin(angulo) + v.dy * math.cos(angulo),
        );
  }

  void retangulo(double l, double t, double rr, double b) {
    path
      ..moveTo(r(l, t).dx, r(l, t).dy)
      ..lineTo(r(rr, t).dx, r(rr, t).dy)
      ..lineTo(r(rr, b).dx, r(rr, b).dy)
      ..lineTo(r(l, b).dx, r(l, b).dy)
      ..close();
  }

  retangulo(4, 8.5, 7, 15.5);
  retangulo(17, 8.5, 20, 15.5);
  path
    ..moveTo(r(7, 12).dx, r(7, 12).dy)
    ..lineTo(r(17, 12).dx, r(17, 12).dy)
    ..moveTo(r(2.5, 10.5).dx, r(2.5, 10.5).dy)
    ..lineTo(r(2.5, 13.5).dx, r(2.5, 13.5).dy)
    ..moveTo(r(21.5, 10.5).dx, r(21.5, 10.5).dy)
    ..lineTo(r(21.5, 13.5).dx, r(21.5, 13.5).dy);
}
