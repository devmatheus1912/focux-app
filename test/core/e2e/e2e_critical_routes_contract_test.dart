import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Gate E2E — rotas críticas dos hubs refatorados têm spec Playwright @smoke.
void main() {
  const criticalRoutes = [
    '/dashboard/personal',
    '/chat/inbox',
    '/ia/copiloto',
    '/migracao-magica',
    '/exercicios',
  ];

  test('playwright config and e2e workflow exist', () {
    expect(File('e2e/playwright.config.ts').existsSync(), isTrue);
    expect(File('e2e/package.json').existsSync(), isTrue);
    expect(File('.github/workflows/e2e.yml').existsSync(), isTrue);
  });

  test('critical routes P0 smoke spec covers refactored hubs', () {
    final spec = File('e2e/tests/personal/11-rotas-criticas-P0.spec.ts')
        .readAsStringSync();
    expect(spec, contains('@p0 @smoke'));
    for (final route in criticalRoutes) {
      if (route == '/dashboard/personal') {
        expect(
          File('e2e/tests/personal/01-dashboard.spec.ts').readAsStringSync(),
          contains(route),
        );
        continue;
      }
      expect(spec, contains(route));
    }
  });

  test('e2e README documents smoke and P0 tags', () {
    final readme = File('e2e/README.md').readAsStringSync();
    expect(readme, contains('@smoke'));
    expect(readme, contains('@p0'));
    expect(readme, contains('npm run test:smoke'));
  });
}
