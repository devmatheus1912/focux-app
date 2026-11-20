import 'package:flutter/material.dart';

import '../theme/brand_tint.dart';
import '../theme/tokens_strip.dart';

/// Chão das páginas: cor sólida, sem brilhos nem degradê (guia de marca,
/// seção 4.6). Claro = paper `#F4F6F8`; escuro = chão petróleo `#0A1A1F`.
///
/// Só a marca própria do personal com estilo Cinematográfico tinge o chão,
/// ainda sólido, com um pouco da primária dela.
class FxChao extends StatelessWidget {
  const FxChao({super.key, required this.child, this.forceDark = false});

  final Widget child;
  final bool forceDark;

  /// Cor do chão para o brilho e a marca do contexto.
  static Color corDe(BuildContext context, {bool forceDark = false}) {
    final claro =
        !forceDark && Theme.of(context).brightness == Brightness.light;
    final marca = BrandTint.maybeOf(context);
    final tinge = marca != null && marca.estilo.tingeFundo;
    return corPara(escuro: !claro, tinta: tinge ? marca.primaria : null);
  }

  /// Cor do chão sem contexto: [tinta] é a primária da marca Cinematográfica.
  static Color corPara({required bool escuro, Color? tinta}) {
    final base = escuro ? TokensStrip.cinematicBg : TokensStrip.paper;
    if (tinta == null) return base;
    return Color.lerp(base, tinta, escuro ? 0.18 : 0.06)!;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: corDe(context, forceDark: forceDark),
      child: child,
    );
  }
}
