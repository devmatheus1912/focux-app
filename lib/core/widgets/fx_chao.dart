import 'package:flutter/material.dart';

import '../theme/brand_tint.dart';
import '../theme/chao_da_marca.dart';
import '../theme/tokens_strip.dart';

/// Chão das páginas: cor sólida, sem brilhos nem degradê (guia de marca,
/// seção 4.6). Claro = paper `#F4F6F8`; escuro = o petróleo `#0A1A1F` na matiz
/// da marca do personal (mesmo brilho; com a cor do Focux, o petróleo exato).
///
/// O estilo Cinematográfico ainda tinge o chão, sólido, com a primária.
class FxChao extends StatelessWidget {
  const FxChao({super.key, required this.child, this.forceDark = false});

  final Widget child;
  final bool forceDark;

  /// Cor do chão para o brilho e a marca do contexto.
  static Color corDe(BuildContext context, {bool forceDark = false}) {
    final theme = Theme.of(context);
    final claro = !forceDark && theme.brightness == Brightness.light;
    final marca = BrandTint.maybeOf(context);
    final tinta = marca != null && marca.estilo.tingeFundo ? marca.primaria : null;
    if (claro) return _tingir(TokensStrip.paper, tinta, escuro: false);
    // O tema da marca já montou o escuro na matiz dela (extensão do tema).
    final tema = theme.extension<TonsEscuros>();
    final chao = tema?.chao ?? tonsEscurosDa(marca?.primaria).chao;
    return _tingir(chao, tinta, escuro: true);
  }

  /// Cor do chão sem contexto. [primaria] dá a matiz do escuro; [tinta] é a
  /// primária da marca Cinematográfica.
  static Color corPara({required bool escuro, Color? primaria, Color? tinta}) {
    final base = escuro ? tonsEscurosDa(primaria).chao : TokensStrip.paper;
    return _tingir(base, tinta, escuro: escuro);
  }

  static Color _tingir(Color base, Color? tinta, {required bool escuro}) {
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
