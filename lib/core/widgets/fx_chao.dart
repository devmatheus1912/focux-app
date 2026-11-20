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
    final base = claro ? TokensStrip.paper : TokensStrip.cinematicBg;
    final marca = BrandTint.maybeOf(context);
    if (marca == null || !marca.estilo.tingeFundo) return base;
    return Color.lerp(base, marca.primaria, claro ? 0.06 : 0.18)!;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: corDe(context, forceDark: forceDark),
      child: child,
    );
  }
}
