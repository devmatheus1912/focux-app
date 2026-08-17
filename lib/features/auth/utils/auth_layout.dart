import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';

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
///
/// [ensureFooter]: reserva extra no fim (rodapé legal / link secundário)
/// para não cortar no home indicator nem sumir atrás do teclado.
EdgeInsets authScrollPadding(
  BuildContext context, {
  double horizontal = TokensStrip.s5,
  double top = 40,
  double bottomExtra = TokensStrip.s5,
  bool ensureFooter = false,
}) {
  final viewBottom = MediaQuery.viewPaddingOf(context).bottom;
  final keyboard = MediaQuery.viewInsetsOf(context).bottom;
  final keyboardReserve = keyboard > 0 ? TokensStrip.s5 : 0.0;
  final footerReserve = ensureFooter ? TokensStrip.s5 : 0.0;
  return EdgeInsets.fromLTRB(
    horizontal,
    top,
    horizontal,
    bottomExtra + viewBottom + keyboardReserve + footerReserve,
  );
}
