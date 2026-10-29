import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'focux_contrast.dart';

/// Derives soft/deep/accent variants from any dynamic primary color.
/// Used by white-label: personal's corPrimaria is passed here to generate
/// a harmonious set of tints that work across light and dark modes.
///
/// Tested with azul petróleo (default Focux), warm reds, greens, purples.
class BrandPalette {
  static const Color defaultPrimary = Color(0xFF0B4F5C);
  static const Color defaultSecondary = Color(0xFF3D9AAD);
  static const Color defaultInk = Color(0xFF083D47);
  /// Fundos de referência (claro/escuro) para checar contraste e pintar prévias.
  static const Color fundoClaroReferencia = Color(0xFFF6F4FA);
  static const Color fundoEscuroReferencia = Color(0xFF14161A);
  static const String defaultPrimaryHex = '#0B4F5C';
  static const String defaultSecondaryHex = '#3D9AAD';

  /// Defaults anteriores (cyan-teal) — reset / detecção de perfil legado.
  static const String legacyPrimaryHex = '#13C2C2';
  static const String legacySecondaryHex = '#007D8A';
  static const String legacyPrimaryHexOlder = '#1EC8C8';
  static const String legacySecondaryHexOlder = '#0097A7';

  /// Tom médio oficial (hover claro / links) — aceito como secondary default.
  static const String brandMidHex = '#0A6B7A';

  static const Set<String> _primaryDefaults = {
    defaultPrimaryHex,
    legacyPrimaryHex,
    legacyPrimaryHexOlder,
  };

  static const Set<String> _secondaryDefaults = {
    defaultSecondaryHex,
    brandMidHex,
    legacySecondaryHex,
    legacySecondaryHexOlder,
    '#4DD0E1',
  };

  static bool isDefaultBrandColors({
    String? corPrimaria,
    String? corSecundaria,
  }) {
    final primary = _normalizeHex(corPrimaria);
    final secondary = _normalizeHex(corSecundaria);
    return (primary == null || _primaryDefaults.contains(primary)) &&
        (secondary == null || _secondaryDefaults.contains(secondary));
  }

  /// Hex salvo no perfil → cor de tema.
  /// Cyan legado (`#13C2C2` / `#1EC8C8`) e o petróleo atual mapeiam para
  /// [defaultPrimary]. White-label customizado passa intacto.
  ///
  /// Login usa [EagleTokens.brand] direto; após auth o tema vinha do
  /// `corPrimaria` do BE — sem este remap a shell inteira ficava cyan.
  static Color resolveStoredPrimary(String? raw) {
    final norm = _normalizeHex(raw);
    if (norm == null || _primaryDefaults.contains(norm)) {
      return defaultPrimary;
    }
    final parsed = int.tryParse(norm.replaceFirst('#', '0xFF'));
    if (parsed == null) return defaultPrimary;
    return Color(parsed);
  }

  /// Idem para secondary: legado `#007D8A` / `#0097A7` → [defaultSecondary].
  static Color resolveStoredSecondary(String? raw) {
    final norm = _normalizeHex(raw);
    if (norm == null || _secondaryDefaults.contains(norm)) {
      return defaultSecondary;
    }
    final parsed = int.tryParse(norm.replaceFirst('#', '0xFF'));
    if (parsed == null) return defaultSecondary;
    return Color(parsed);
  }

  static String toHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  /// Slightly darkens a brand color for large surfaces and CTAs.
  static Color softened(Color primary, {double amount = 0.08}) {
    return Color.lerp(primary, EagleTokens.brandDeep, amount)!;
  }

  static String? _normalizeHex(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim().toUpperCase();
    if (!value.startsWith('#')) return '#$value';
    return value;
  }

  static Color soft(Color primary, {bool dark = false}) {
    final hsl = HSLColor.fromColor(primary);
    if (dark) {
      // In dark mode, produce a deeply desaturated, low-lightness tint
      return hsl
          .withSaturation((hsl.saturation * 0.35).clamp(0.0, 1.0))
          .withLightness(0.14)
          .toColor();
    }
    // In light mode, produce a very light tint with reduced saturation
    return hsl
        .withSaturation((hsl.saturation * 0.30).clamp(0.0, 1.0))
        .withLightness(0.93)
        .toColor();
  }

  static Color softer(Color primary, {bool dark = false}) {
    final hsl = HSLColor.fromColor(primary);
    if (dark) {
      return hsl
          .withSaturation((hsl.saturation * 0.25).clamp(0.0, 1.0))
          .withLightness(0.10)
          .toColor();
    }
    return hsl
        .withSaturation((hsl.saturation * 0.20).clamp(0.0, 1.0))
        .withLightness(0.96)
        .toColor();
  }

  static Color deep(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    final next = hsl
        .withSaturation((hsl.saturation * 0.95).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * 0.55).clamp(0.0, 1.0));
    return next.toColor();
  }

  static Color accent(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    final next = hsl
        .withSaturation((hsl.saturation * 0.75).clamp(0.0, 1.0))
        .withLightness((hsl.lightness + 0.18).clamp(0.0, 1.0));
    return next.toColor();
  }

  /// H2 section titles on page surfaces — deep brand (light) / glow (dark).
  static Color sectionHeading(Color primary, {required bool dark}) =>
      dark ? accent(primary) : deep(primary);

  /// Section action links and chips — vivid in light, glow in dark.
  static Color sectionAction(Color primary, {required bool dark}) =>
      dark ? accent(primary) : primary;

  /// Plain-text section links (Ver tudo, Ver lista) — editorial in light.
  static Color sectionLink(Color primary, {required bool dark}) =>
      dark ? accent(primary) : Color.lerp(deep(primary), primary, 0.2)!;

  /// Icons and micro-labels in branded rows.
  static Color sectionAccent(Color primary, {required bool dark}) =>
      dark ? accent(primary) : deep(primary);

  /// Card principal da Home no estilo Cinematográfico: a primária **sólida**,
  /// levemente escurecida, com texto claro por cima. Mesma matiz de cima para
  /// baixo, só a luminosidade varia (no máximo [cardDeMarcaVariacao]); sem
  /// segunda cor, sem brilho. A cor salva do personal não muda: só a aplicada.
  ///
  /// Trava de contraste: a luminosidade desce até o branco passar AA (4.5:1)
  /// nos dois extremos, então qualquer cor escolhida fica legível.
  static CardDeMarca cardDeMarca(Color primaria, {required bool dark}) {
    final hsl = HSLColor.fromColor(primaria);
    // Teto de luminosidade: o card é "levemente escurecido", e no escuro fica
    // um pouco mais fundo para não brilhar sobre o fundo.
    final teto = dark ? 0.26 : 0.34;
    var topo = hsl.lightness > teto ? teto : hsl.lightness;
    topo = topo.clamp(0.14, teto).toDouble();
    final saturacao = hsl.saturation.clamp(0.0, 0.85).toDouble();

    Color cor(double l) =>
        hsl.withSaturation(saturacao).withLightness(l.clamp(0.0, 1.0)).toColor();
    bool passa(Color c) =>
        FocuxContrast.meetsWcagAa(Colors.white, c);

    var fundo = cor(topo);
    while (!passa(fundo) && topo > 0.05) {
      topo -= 0.01;
      fundo = cor(topo);
    }
    final fim = cor((topo - cardDeMarcaVariacao).clamp(0.04, 1.0).toDouble());
    return CardDeMarca(fundo: fundo, fundoFim: fim, sobre: Colors.white);
  }

  /// Quanto a luminosidade (HSL) pode variar do topo ao fim do card sólido.
  static const double cardDeMarcaVariacao = 0.06;

  /// Tinta de superfície a 4% (claro) / 6% (escuro): fundos que sentem a marca
  /// sem virar cor chapada.
  static Color surfaceTint(Color primary, {required bool dark}) =>
      primary.withValues(alpha: dark ? 0.06 : 0.04);

  /// Acento da cor secundária para ícones, anéis e selos. Se a secundária não
  /// tiver contraste (3:1, texto grande/ícone) com o [background], cai para o
  /// acento da primária.
  static Color secondaryAccent(
    Color secondary,
    Color primary, {
    required bool dark,
    required Color background,
  }) {
    // No escuro, a secundária entra mais clara; no claro, mais funda.
    final candidata = dark ? accent(secondary) : deep(secondary);
    if (FocuxContrast.meetsWcagAa(candidata, background, largeText: true)) {
      return candidata;
    }
    if (FocuxContrast.meetsWcagAa(secondary, background, largeText: true)) {
      return secondary;
    }
    return sectionAccent(primary, dark: dark);
  }
}

/// Cores do card sólido da marca: [fundo] no topo, [fundoFim] embaixo (mesma
/// matiz) e [sobre] para texto, ícones e o botão invertido.
class CardDeMarca {
  const CardDeMarca({
    required this.fundo,
    required this.fundoFim,
    required this.sobre,
  });

  final Color fundo;
  final Color fundoFim;
  final Color sobre;

  LinearGradient get degrade => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [fundo, fundoFim],
  );
}
