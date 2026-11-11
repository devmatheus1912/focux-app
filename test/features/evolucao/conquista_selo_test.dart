import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_selo_glifos.dart';
import 'package:focux_app/features/evolucao/data/meta_corporal.dart';
import 'package:focux_app/features/evolucao/widgets/conquista_cartao.dart';
import 'package:focux_app/features/evolucao/widgets/conquista_selo.dart';
import 'package:google_fonts/google_fonts.dart';

Conquista _c(ConquistaTipo tipo, {String? metrica}) => Conquista(
  chave: 'x',
  tipo: tipo,
  titulo: '+4,0 kg',
  detalhe: 'De 80 para 84 kg em 30 dias',
  data: DateTime(2026, 11, 11),
  valor: '+4,0 kg',
  metrica: metrica,
);

void main() {
  test('glifo de cada conquista', () {
    expect(conquistaGlifo(_c(ConquistaTipo.meta, metrica: 'PESO')), FxSeloGlifo.balanca);
    expect(conquistaGlifo(_c(ConquistaTipo.meta, metrica: 'CINTURA')), FxSeloGlifo.fitaMetrica);
    expect(conquistaGlifo(_c(ConquistaTipo.meta, metrica: 'QUADRIL')), FxSeloGlifo.fitaMetrica);
    expect(conquistaGlifo(_c(ConquistaTipo.meta, metrica: 'BRACO')), FxSeloGlifo.biceps);
    expect(conquistaGlifo(_c(ConquistaTipo.meta, metrica: 'GORDURA')), FxSeloGlifo.tronco);
    expect(conquistaGlifo(_c(ConquistaTipo.mantido, metrica: 'MASSA')), FxSeloGlifo.anilhas);
    expect(conquistaGlifo(_c(ConquistaTipo.recorde)), FxSeloGlifo.trofeu);
  });

  test('selo sem imagem: desenhado em código', () {
    for (final f in [
      'lib/features/evolucao/widgets/conquista_selo.dart',
      'lib/core/widgets/fx_selo_glifos.dart',
    ]) {
      final src = File(f).readAsStringSync();
      expect(src, isNot(contains('Image.asset')));
      expect(src, isNot(contains('.png')));
    }
  });

  testWidgets('os 13 glifos desenham sem erro', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [
            for (final g in FxSeloGlifo.values)
              ConquistaSelo(tipo: ConquistaTipo.meta, glifo: g, tamanho: 64),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(ConquistaSelo), findsNWidgets(13));
  });

  testWidgets('story: nada de texto nas áreas que o Instagram cobre', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final mostrar in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: ConquistaCartao(
              conquista: _c(ConquistaTipo.meta, metrica: 'PESO'),
              mostrarValor: mostrar,
              marca: (logoUrl: null, nome: 'Matheus'),
            ),
          ),
        ),
      );
      for (final texto in tester.widgetList<Text>(find.byType(Text))) {
        final r = tester.getRect(find.byWidget(texto));
        expect(r.top, greaterThanOrEqualTo(ConquistaCartao.livreTopo - 0.5));
        expect(
          r.bottom,
          lessThanOrEqualTo(ConquistaCartao.altura - ConquistaCartao.livreBase + 0.5),
        );
      }
    }
  });
}
