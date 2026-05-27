import 'package:flutter/material.dart';

bool reduceMotionOf(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Limita escala de fonte do sistema para layouts de marketing estáveis.
TextScaler clampedTextScaler(BuildContext context, {double maxScale = 1.2}) {
  final scaler = MediaQuery.textScalerOf(context);
  final scale = scaler.scale(1).clamp(1.0, maxScale);
  return TextScaler.linear(scale);
}
