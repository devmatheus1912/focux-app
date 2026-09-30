import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Goldens no Ubuntu: smoke via [expectFocuxGolden], pixel no Win/mac.
void main() {
  test('suites de golden usam tag e skip de pixel no Linux', () {
    final dir = Directory('test');
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) {
          final p = f.path.replaceAll(r'\', '/');
          return p.endsWith('_test.dart') &&
              (p.contains('golden') ||
                  f.readAsStringSync().contains("goldens/"));
        })
        .toList();

    expect(files, isNotEmpty);
    for (final file in files) {
      final src = file.readAsStringSync();
      final path = file.path.replaceAll(r'\', '/');
      expect(
        src.contains("@Tags(['golden'])") || src.contains('@Tags(["golden"])'),
        isTrue,
        reason: '$path precisa de @Tags([golden])',
      );
      expect(
        src.contains('expectFocuxGolden'),
        isTrue,
        reason: '$path deve comparar via expectFocuxGolden',
      );
    }
  });

  test('CI roda goldens separado e unitários excluem a tag', () {
    final yml = File('.github/workflows/analyze.yml').readAsStringSync();
    expect(yml, contains('--exclude-tags golden'));
    expect(yml, contains('--tags golden'));
    expect(yml, contains('expectFocuxGolden'));
  });
}
