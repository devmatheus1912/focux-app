import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_aneis_concentricos.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/data/meta_corporal.dart';
import 'package:focux_app/features/evolucao/widgets/evolucao_metas_bloco.dart';

void main() {
  test('toda medida da tela pode virar meta', () {
    expect(metaMetricas, containsAll(['PESO', 'CINTURA', 'QUADRIL', 'BRACO', 'GORDURA', 'MASSA']));
    expect(metaUnidade('QUADRIL'), 'cm');
    expect(metaUnidade('MASSA'), '%');
    expect(metaMetricaRotulo('MASSA'), 'Massa magra');
  });

  test('leitura ao digitar o alvo', () {
    expect(metaLeituraDoAlvo('CINTURA', 60, 55), 'Reduzir 5,0 cm');
    expect(metaLeituraDoAlvo('PESO', 100, 110), 'Aumentar 10,0 kg');
    expect(metaLeituraDoAlvo('PESO', 100, 100), isNull);
    expect(metaLeituraDoAlvo('PESO', 100, null), isNull);
  });

  test('sem medida registrada não há leitura atual', () {
    const home = EvolucaoHomeBundle(medidas: [], recordes: []);
    expect(metaLeituraAtual('QUADRIL', home), isNull);
    expect(metaLeituraAtual('MASSA', home), isNull);
    expect(
      metaLeituraAtual(
        'MASSA',
        const EvolucaoHomeBundle(
          medidas: [],
          recordes: [],
          massa: [(data: '02/11', valor: 40)],
        ),
      )?.valor,
      40,
    );
  });

  test('cor do anel é da mesma família em qualquer fundo, com contraste', () {
    const marca = Color(0xFF0B4F5C);
    double matiz(Color c) => HSLColor.fromColor(c).hue;
    final sobreMarca = fxCoresDeAnel(marca);
    final sobreBranco = fxCoresDeAnel(Colors.white, marca: marca);
    for (var i = 0; i < 3; i++) {
      expect((matiz(sobreMarca[i]) - matiz(sobreBranco[i])).abs(), lessThan(1));
    }
  });
}
