import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/design_system/focux_surfaces.dart';

import '../../support/screen_source_bundle.dart';

final _pathPattern = RegExp(r"path:\s*'([^']+)'");

Set<String> _routerPaths() {
  final dir = Directory('lib/core/router');
  final paths = <String>{};
  for (final file in dir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    for (final match in _pathPattern.allMatches(file.readAsStringSync())) {
      paths.add(match.group(1)!);
    }
  }
  return paths;
}

void main() {
  test('FocuxSurfaces catalog files exist', () {
    for (final path in FocuxSurfaces.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    for (final path in FocuxSurfaces.automatedGates) {
      expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
    }
  });

  test('every GoRouter path is classified in FocuxSurfaces', () {
    final routerPaths = _routerPaths();
    expect(routerPaths, isNotEmpty);
    final missing = routerPaths.difference(FocuxSurfaces.catalog.keys.toSet());
    expect(missing, isEmpty, reason: 'Rotas sem tipo: $missing');
    final extra = FocuxSurfaces.catalog.keys.toSet().difference(routerPaths);
    expect(extra, isEmpty, reason: 'Catálogo com rota morta: $extra');
  });

  test('FxShellAppBar no longer defaults to maybePop', () {
    final source =
        File('lib/core/widgets/fx_shell_scaffold.dart').readAsStringSync();
    expect(source, isNot(contains('Navigator.maybePop')));
    expect(source, contains('safePopOrGo'));
    expect(source, contains('fallbackLocation'));
    expect(source, contains('FxKeyboardDismissScope'));
  });

  test('S5/S6 conversion chrome dismisses the keyboard', () {
    final authShell =
        File('lib/features/auth/widgets/auth_shell.dart').readAsStringSync();
    expect(authShell, contains('FxKeyboardDismissScope'));

    final scaffold =
        File('lib/core/widgets/fx_shell_scaffold.dart').readAsStringSync();
    expect(scaffold, contains('dismissKeyboard'));
    expect(scaffold, contains('FocuxSurfaces.hasInputOf'));
  });

  test('S6 auth screens keep a single primary CTA', () {
    const screens = [
      'lib/features/auth/screens/login_screen.dart',
      'lib/features/auth/screens/register_screen.dart',
      'lib/features/auth/screens/register_aluno_screen.dart',
      'lib/features/auth/screens/esqueci_senha_screen.dart',
      'lib/features/auth/screens/resetar_senha_screen.dart',
      'lib/features/auth/screens/resetar_senha_verificar_codigo_screen.dart',
      'lib/features/auth/screens/definir_senha_aluno_screen.dart',
    ];
    for (final path in screens) {
      final source = readScreenSourceBundle(path);
      expect(
        RegExp('FxLiquidPrimaryButton').allMatches(source).length,
        1,
        reason: '$path deve ter exatamente 1 FxLiquidPrimaryButton',
      );
    }
  });

  test(
    'satellite FxShellAppBar uses safePopOrGo, fallbackLocation or catalog',
    () {
      final appBar =
          File('lib/core/widgets/fx_shell_scaffold.dart').readAsStringSync();
      expect(appBar, contains('FocuxSurfaces.logicalParentOf'));
      expect(appBar, contains('safePopOrGo(context, parent)'));
    },
  );
}
