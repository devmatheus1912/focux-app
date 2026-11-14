import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/focux_contrast.dart';
import 'package:focux_app/features/evolucao/widgets/conquista_selo.dart';

void main() {
  const marcas = {
    'teal Focux': Color(0xFF0B4F5C),
    'escura': Color(0xFF1A1A2E),
    'clara': Color(0xFFB8E0D2),
    'vermelha': Color(0xFFC73A3A),
  };

  test('sobre a marca, o metal se destaca do fundo (3:1) ou volta ao padrão', () {
    for (final e in marcas.entries) {
      final marca = e.value;
      final sobre = conquistaSeloCores(marca, sobreMarca: true);
      final padrao = conquistaSeloCores(marca);
      final contraste = FocuxContrast.contrastRatio(sobre.metalMedio, marca);
      expect(
        contraste >= conquistaSeloContrasteSobreMarca ||
            sobre.metalMedio == padrao.metalMedio,
        isTrue,
        reason: '${e.key}: $contraste',
      );
    }
  });

  test('marca escura (o caso do print) clareia o metal', () {
    const teal = Color(0xFF0B4F5C);
    final sobre = conquistaSeloCores(teal, sobreMarca: true);
    expect(sobre.metalMedio, isNot(conquistaSeloCores(teal).metalMedio));
    expect(
      FocuxContrast.contrastRatio(sobre.metalMedio, teal),
      greaterThanOrEqualTo(conquistaSeloContrasteSobreMarca),
    );
  });

  test('fora da marca nada muda', () {
    const teal = Color(0xFF0B4F5C);
    expect(conquistaSeloCores(teal), conquistaSeloCores(teal, sobreMarca: false));
  });

  test('sobre a marca o metal mantém o matiz da marca (não vira prata)', () {
    const teal = Color(0xFF0B4F5C);
    final sobre = conquistaSeloCores(teal, sobreMarca: true);
    final matizMarca = HSLColor.fromColor(teal).hue;
    for (final tom in [sobre.metalClaro, sobre.metalMedio, sobre.metalEscuro]) {
      final hsl = HSLColor.fromColor(tom);
      expect((hsl.hue - matizMarca).abs(), lessThan(2), reason: '$tom');
      expect(hsl.saturation, greaterThanOrEqualTo(conquistaSeloSaturacaoMinima - 0.01));
    }
  });

  test('marca cinza continua cinza', () {
    const cinza = Color(0xFF333333);
    final tom = conquistaMetalTingido(cinza, 0.78);
    expect(HSLColor.fromColor(tom).saturation, lessThan(0.05));
  });
}
