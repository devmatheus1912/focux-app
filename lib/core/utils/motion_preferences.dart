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

/// Limita escala de fonte do sistema para layouts de marketing estáveis.
TextScaler clampedTextScaler(BuildContext context, {double maxScale = 1.2}) {
  final scaler = MediaQuery.textScalerOf(context);
  final scale = scaler.scale(1).clamp(1.0, maxScale);
  return TextScaler.linear(scale);
}
