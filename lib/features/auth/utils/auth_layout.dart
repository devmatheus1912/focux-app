import 'package:flutter/material.dart';

/// Lockup padrão nas telas de formulário auth (login, register, esqueci, reset).
const double kAuthFormLogoWidth = 118.0;

/// Largura do logo adaptada à altura da viewport (evita empurrar CTAs no Pixel/teclado).
double authLogoWidthFor(BuildContext context, {bool withTagline = false}) {
  final height = MediaQuery.sizeOf(context).height;
  if (height < 700) return withTagline ? 104.0 : 108.0;
  if (height < 780) return withTagline ? 110.0 : 112.0;
  return kAuthFormLogoWidth;
}

/// Padding de scroll com safe-area inferior + folga para home indicator / teclado.
EdgeInsets authScrollPadding(
  BuildContext context, {
  double horizontal = 22,
  double top = 48,
  double bottomExtra = 20,
}) {
  final viewBottom = MediaQuery.viewPaddingOf(context).bottom;
  final keyboard = MediaQuery.viewInsetsOf(context).bottom;
  return EdgeInsets.fromLTRB(
    horizontal,
    top,
    horizontal,
    bottomExtra + viewBottom + (keyboard > 0 ? 12 : 0),
  );
}
