import 'package:flutter/material.dart';

bool reduceMotionOf(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Standard UI motion duration; zero when the OS requests reduced motion.
Duration fxMotionDuration(
  BuildContext context, {
  Duration normal = const Duration(milliseconds: 220),
}) =>
    reduceMotionOf(context) ? Duration.zero : normal;

/// Millisecond helper for [AnimatedSize] / [AnimatedContainer].
int fxMotionDurationMs(
  BuildContext context, {
  int normal = 220,
}) =>
    reduceMotionOf(context) ? 0 : normal;

/// Teto global do Dynamic Type — igual em todas as larguras de tela.
const double kAppMaxTextScale = 1.3;

/// Piso global — evita texto ilegível quando o sistema reduz a fonte.
const double kAppMinTextScale = 0.85;

/// Escala efetiva do app a partir da escala do sistema.
TextScaler appTextScaler(TextScaler system) => system.clamp(
  minScaleFactor: kAppMinTextScale,
  maxScaleFactor: kAppMaxTextScale,
);

/// Limita escala de fonte do sistema para layouts de marketing estáveis.
TextScaler clampedTextScaler(BuildContext context, {double maxScale = 1.2}) =>
    MediaQuery.textScalerOf(
      context,
    ).clamp(minScaleFactor: kAppMinTextScale, maxScaleFactor: maxScale);
