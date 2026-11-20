import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Tons do modo escuro (chão, superfícies e borda) na cor da marca. Vai no
/// tema como extensão: quem pinta o escuro lê daqui ([TonsEscuros.de]).
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

  /// Os tons do tema; sem a extensão (tema genérico), o petróleo.
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

  /// O petróleo do Focux (guia de marca, seção 4.6).
  static const focux = TonsEscuros(
    chao: EagleTokens.darkBg,
    superficie: EagleTokens.darkCard,
    superficieAlta: EagleTokens.darkCardHi,
    linha: EagleTokens.darkLine,
  );
}

/// Matiz do Focux (`#0B4F5C` e o acento `#0E93A8` ficam entre 188° e 190°).
const double _matizFocux = 190;

/// O escuro do app na matiz da primária do personal, com a saturação e a
/// luminosidade do petróleo do Focux. Como a luminosidade não muda, o
/// contraste do texto é o mesmo em qualquer marca.
///
/// Cor perto da matiz do Focux (ou nenhuma) dá exatamente o petróleo; cor
/// quase sem saturação (cinza, preto, branco) dá um escuro neutro.
TonsEscuros tonsEscurosDa(Color? primaria) {
  if (primaria == null) return TonsEscuros.focux;
  final hsl = HSLColor.fromColor(primaria);
  if (hsl.saturation < 0.15) return _tons(null);
  final distancia = (hsl.hue - _matizFocux).abs();
  if (distancia.clamp(0, 360 - distancia) <= 8) return TonsEscuros.focux;
  return _tons(hsl.hue);
}

/// Mesmos pares saturação/luminosidade do petróleo (`#0A1A1F`, `#10262C`,
/// `#16323A`, `#1B3A42`). Sem [matiz], neutro.
TonsEscuros _tons(double? matiz) {
  Color tom(double saturacao, double luminosidade) =>
      HSLColor.fromAHSL(
        1,
        matiz ?? 0,
        matiz == null ? 0 : saturacao,
        luminosidade,
      ).toColor();
  return TonsEscuros(
    chao: tom(0.51, 0.08),
    superficie: tom(0.47, 0.118),
    superficieAlta: tom(0.45, 0.157),
    linha: tom(0.42, 0.182),
  );
}
