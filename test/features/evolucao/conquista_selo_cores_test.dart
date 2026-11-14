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
}
