import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_action_chip.dart';

void main() {
  const primary = Color(0xFF0B4F5C);

  Widget host(Widget child) => MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 360, child: Wrap(children: [child]))),
    ),
  );

  testWidgets('chip keeps intrinsic width inside Wrap', (tester) async {
    await tester.pumpWidget(
      host(
        FxActionChip(
          label: 'Escrever',
          accent: primary,
          isDark: false,
          onPressed: () {},
        ),
      ),
    );
    expect(tester.getSize(find.byType(FxActionChip)).width, lessThan(200));
  });

  testWidgets('tonal is the default; solid only when asked', (tester) async {
    await tester.pumpWidget(
      host(
        FxActionChip(
          label: 'Mais',
          accent: primary,
          isDark: false,
          onPressed: () {},
        ),
      ),
    );
    final tonal = tester.widget<Material>(
      find.descendant(
        of: find.byType(FxActionChip),
        matching: find.byType(Material),
      ),
    );
    expect(tonal.color, isNot(primary));
    expect(tonal.elevation, 0);

    await tester.pumpWidget(
      host(
        FxActionChip(
          label: 'Cobrar',
          accent: primary,
          isDark: false,
          solid: true,
          onPressed: () {},
        ),
      ),
    );
    final solid = tester.widget<Material>(
      find.descendant(
        of: find.byType(FxActionChip),
        matching: find.byType(Material),
      ),
    );
    expect(solid.color, primary);
  });

  test('at most one solid chip per feature file (§11 one P0)', () {
    final offenders = <String>[];
    for (final f in Directory('lib/features').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final n = 'solid: true'.allMatches(f.readAsStringSync()).length;
      if (n > 1) offenders.add('${f.path} ($n)');
    }
    expect(offenders, isEmpty);
  });

  test('money green never paints an action', () {
    final offenders = <String>[];
    for (final f in Directory('lib/features').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.readAsStringSync().contains('accent: EagleTokens.moneyGreen')) {
        offenders.add(f.path);
      }
    }
    expect(offenders, isEmpty);
  });
}
