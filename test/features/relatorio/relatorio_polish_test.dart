import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('relatorio usa polish: cards, erro amigavel e a11y', () {
    final screen = readScreenSourceBundle(
      'lib/features/relatorio/screens/relatorio_screen.dart',
    );
    final global = File(
      'lib/features/relatorio/screens/relatorio_global_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('fxListCardDecoration'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('Semantics('));
    expect(screen, contains("label: 'Exportar relatório em PDF'"));

    expect(global, contains('FxContentWidthLimiter'));
    expect(global, contains('fxScreenA11yScope'));
    expect(global, contains('dashboardHeroCaptionOnTeal'));
    expect(global, contains('dashboardHeroMutedOnTealStyle'));
    expect(global, contains('fxListCardDecoration'));
    expect(global, isNot(contains('Colors.white70')));
  });
}
