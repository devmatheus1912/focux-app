import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/cinematic_mesh_background.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Brightness brilho,
  bool liso = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brilho),
      home: CinematicMeshBackground(
        flatBackground: liso,
        child: const Center(child: Text('conteudo')),
      ),
    ),
  );
}

void main() {
  test('o código não tem mais grade de fundo', () {
    final lib = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final f in lib) {
      final src = f.readAsStringSync();
      for (final termo in [
        '_CinematicGridPainter',
        'showGrid',
        'animateGridIn',
      ]) {
        expect(src.contains(termo), isFalse, reason: '$termo em ${f.path}');
      }
    }
  });

  for (final brilho in [Brightness.dark, Brightness.light]) {
    testWidgets('malha ${brilho.name} desenha o filho sem controlador', (
      tester,
    ) async {
      await _pump(tester, brilho: brilho);
      expect(find.text('conteudo'), findsOneWidget);
      expect(find.byType(CinematicMeshBackground), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fundo liso ${brilho.name} também desenha o filho', (
      tester,
    ) async {
      await _pump(tester, brilho: brilho, liso: true);
      expect(find.text('conteudo'), findsOneWidget);
    });
  }

  test('é StatelessWidget (sem animação de grade)', () {
    expect(
      const CinematicMeshBackground(child: SizedBox()),
      isA<StatelessWidget>(),
    );
  });
}
