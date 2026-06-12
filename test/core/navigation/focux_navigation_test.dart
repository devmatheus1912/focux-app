import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/navigation/focux_navigation.dart';

void main() {
  test('FocuxNavigation catalog lists core sources', () {
    for (final path in FocuxNavigation.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    expect(FocuxNavigation.version, isNotEmpty);
    expect(FocuxNavigation.shellTabPaths.length, 5);
  });

  test('safe navigation documents shell tab switcher', () {
    final source =
        File('lib/core/router/safe_navigation.dart').readAsStringSync();
    expect(source, contains('goPersonalShellTab'));
    expect(source, contains('safePopOrGo'));
    expect(source, contains('Never `push` these paths'));
  });

  test('role home resolves personal vs aluno dashboard', () {
    final source = File('lib/core/router/role_home.dart').readAsStringSync();
    expect(source, contains('roleHomePath'));
    expect(source, contains('/dashboard/personal'));
    expect(source, contains('/dashboard/aluno'));
  });
}
