import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/widgets/perfil_conquistas_linha.dart';
import 'package:focux_app/features/evolucao/data/meta_corporal.dart';
import 'package:focux_app/features/evolucao/widgets/conquista_selo.dart';

Conquista _c(int i) => Conquista(
  chave: 'c$i',
  tipo: i.isEven ? ConquistaTipo.meta : ConquistaTipo.recorde,
  titulo: '+$i kg',
  detalhe: 'detalhe',
  data: DateTime(2026, 11, 14 - i),
  valor: '+$i kg',
  metrica: i.isEven ? 'CINTURA' : null,
  exercicio: i.isEven ? null : 'Supino reto',
);

Future<void> _montar(WidgetTester tester, int n) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: PerfilConquistasLinha(
        conquistas: [for (var i = 0; i < n; i++) _c(i)],
        onAbrir: (_) {},
        onVerTodas: () {},
      ),
    ),
  ),
);

void main() {
  testWidgets('sem conquista, nada', (tester) async {
    await _montar(tester, 0);
    expect(find.byType(ConquistaSelo), findsNothing);
    expect(find.text('Meu progresso'), findsNothing);
  });

  testWidgets('até 3: todos os selos e "Meu progresso"', (tester) async {
    await _montar(tester, 2);
    expect(find.byType(ConquistaSelo), findsNWidgets(2));
    expect(find.text('Meu progresso'), findsOneWidget);
    expect(find.textContaining('Ver todas'), findsNothing);
  });

  testWidgets('mais de 3: só 3 selos e "Ver todas (N)"', (tester) async {
    await _montar(tester, 5);
    expect(find.byType(ConquistaSelo), findsNWidgets(3));
    expect(find.text('Ver todas (5)'), findsOneWidget);
  });

  testWidgets('cada selo diz o item embaixo; o toque cobre selo e legenda', (
    tester,
  ) async {
    final abertas = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PerfilConquistasLinha(
            conquistas: [_c(1), _c(2)],
            onAbrir: (c) => abertas.add(c.chave),
            onVerTodas: () {},
          ),
        ),
      ),
    );
    expect(find.text('Supino reto'), findsOneWidget);
    expect(find.text('Cintura'), findsOneWidget);
    await tester.tap(find.text('Cintura'));
    expect(abertas, ['c2']);
    // A legenda não repete na leitura de tela (o grupo já tem o resumo).
    expect(
      find.bySemanticsLabel('Cintura'),
      findsNothing,
    );
  });

  testWidgets('legenda longa quebra em duas linhas e os selos ficam na mesma altura', (
    tester,
  ) async {
    final longa = Conquista(
      chave: 'longa',
      tipo: ConquistaTipo.recorde,
      titulo: '20 kg',
      detalhe: 'detalhe',
      data: DateTime(2026, 11, 11),
      valor: '20 kg',
      exercicio: 'Abdominal bicicleta',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PerfilConquistasLinha(
            conquistas: [longa, _c(2)],
            onAbrir: (_) {},
            onVerTodas: () {},
          ),
        ),
      ),
    );
    final texto = tester.widget<Text>(find.text('Abdominal bicicleta'));
    expect(texto.maxLines, perfilSeloLegendaLinhas);
    final selos = find.byType(ConquistaSelo);
    expect(tester.getTopLeft(selos.at(0)).dy, tester.getTopLeft(selos.at(1)).dy);
  });

  test('o item da conquista é o exercício ou a medida', () {
    expect(_c(1).item, 'Supino reto');
    expect(_c(2).item, 'Cintura');
  });

  test('mini-anéis saíram do app', () {
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is File && f.path.endsWith('.dart')) {
        expect(
          f.readAsStringSync().contains('EvolucaoMiniAneis'),
          isFalse,
          reason: f.path,
        );
      }
    }
  });

  test('folha do personal termina em Parabenizar', () {
    final folha = File(
      'lib/features/evolucao/widgets/evolucao_conquistas.dart',
    ).readAsStringSync();
    expect(folha, isNot(contains('onVer')));
  });
}
