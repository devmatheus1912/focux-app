@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/migracao_harness.dart';
import '../../support/tolerant_golden_comparator.dart';

Future<void> _fecha(WidgetTester tester) async {
  // Sem backend de verdade, avisos e atualização do plano têm timer: deixa terminar.
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  for (final escuro in [false, true]) {
    final sufixo = escuro ? '_dark' : '';

    testWidgets('migração, etapa 1 em foto (escuro: $escuro)', (tester) async {
      await abrirMigracao(tester, alunos: [], detalhes: [], escuro: escuro);
      await tester.tap(find.text('Foto ou print').first);
      await assentarMigracao(tester);
      await expectFocuxGolden(
        find.byKey(const ValueKey('tela')),
        'goldens/migracao_etapa1_foto_390$sufixo.png',
      );
      await _fecha(tester);
    });

    testWidgets('migração, etapa 2 (escuro: $escuro)', (tester) async {
      await abrirMigracao(
        tester,
        alunos: [
          linhaMigracao('Maria Silva', telefone: '11988887777'),
          linhaMigracao('João Pedro Souza', email: 'joao.pedro@gmail.com'),
        ],
        ignorados: 3,
        amostras: ['Alunos Buscar', 'Último treino há 3 dias', 'Hoje 08:00'],
        detalhes: [],
        escuro: escuro,
      );
      await ateRevisaoMigracao(tester);
      await expectFocuxGolden(
        find.byKey(const ValueKey('tela')),
        'goldens/migracao_etapa2_390$sufixo.png',
      );
      await _fecha(tester);
    });

    testWidgets('migração, etapa 3 (escuro: $escuro)', (tester) async {
      await abrirMigracao(
        tester,
        alunos: [
          linhaMigracao('Ana', email: 'ana@x.com'),
          linhaMigracao('João Lima', email: 'joao@gmail.com'),
          linhaMigracao('Carlos Lima', telefone: '11988887777'),
          linhaMigracao('Duda Reis'),
        ],
        detalhes: [
          detalheMigracao('Ana', email: 'ana@x.com', emailEnviado: true, emailReal: true, id: 1),
          detalheMigracao('João Lima', email: 'joao@gmail.com', emailReal: true, id: 2),
          detalheMigracao('Carlos Lima', telefone: '11988887777', id: 3),
          detalheMigracao('Duda Reis', id: 4),
        ],
        escuro: escuro,
      );
      await ateRevisaoMigracao(tester);
      await ateResultadoMigracao(tester, 'Importar 4 alunos');
      await expectFocuxGolden(
        find.byKey(const ValueKey('tela')),
        'goldens/migracao_etapa3_390$sufixo.png',
      );
    });
  }
}
