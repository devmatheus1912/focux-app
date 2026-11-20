import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Tons do modo escuro: chão, superfícies e borda.
///
/// Marca Focux: petróleo (guia de marca, seção 4.6). Marca própria do
/// personal: grafite neutro, para qualquer cor dela ficar bem por cima. A cor
/// da marca vai no card principal, nos botões e nos ícones, nunca no fundo.
///
/// Vai no tema como extensão; as telas leem por `context.tons`.
class TonsEscuros extends ThemeExtension<TonsEscuros> {
  const TonsEscuros({
    required this.chao,
    required this.superficie,
    required this.superficieAlta,
    required this.linha,
  });

  final Color chao;
  final Color superficie;
  final Color superficieAlta;
  final Color linha;

  /// Petróleo do Focux.
  static const focux = TonsEscuros(
    chao: EagleTokens.darkBg,
    superficie: EagleTokens.darkCard,
    superficieAlta: EagleTokens.darkCardHi,
    linha: EagleTokens.darkLine,
  );

  /// Grafite neutro da marca própria (mesma luminosidade do petróleo, sem cor).
  static const grafite = TonsEscuros(
    chao: Color(0xFF0E1113),
    superficie: Color(0xFF171B1E),
    superficieAlta: Color(0xFF1E2327),
    linha: Color(0xFF262B30),
  );

  /// Os tons do tema; tema sem a extensão (genérico, testes) usa o petróleo.
  static TonsEscuros de(ThemeData theme) =>
      theme.extension<TonsEscuros>() ?? focux;

  @override
  TonsEscuros copyWith({
    Color? chao,
    Color? superficie,
    Color? superficieAlta,
    Color? linha,
  }) => TonsEscuros(
    chao: chao ?? this.chao,
    superficie: superficie ?? this.superficie,
    superficieAlta: superficieAlta ?? this.superficieAlta,
    linha: linha ?? this.linha,
  );

  @override
  TonsEscuros lerp(TonsEscuros? other, double t) {
    if (other == null) return this;
    return TonsEscuros(
      chao: Color.lerp(chao, other.chao, t)!,
      superficie: Color.lerp(superficie, other.superficie, t)!,
      superficieAlta: Color.lerp(superficieAlta, other.superficieAlta, t)!,
      linha: Color.lerp(linha, other.linha, t)!,
    );
  }
}

/// Atalho das telas: `context.tons.superficie`.
extension TonsDoContexto on BuildContext {
  TonsEscuros get tons => TonsEscuros.de(Theme.of(this));
}

/// Matiz do Focux (`#0B4F5C` e o acento `#0E93A8` ficam entre 188° e 190°).
const double _matizFocux = 190;

/// Petróleo para a marca Focux (ou cor muito perto dela); grafite para
/// qualquer outra marca.
TonsEscuros tonsEscurosDa(Color? primaria) {
  if (primaria == null) return TonsEscuros.focux;
  final hsl = HSLColor.fromColor(primaria);
  final distancia = (hsl.hue - _matizFocux).abs();
  final pertoDoFocux =
      hsl.saturation >= 0.15 && distancia.clamp(0, 360 - distancia) <= 8;
  return pertoDoFocux ? TonsEscuros.focux : TonsEscuros.grafite;
}
