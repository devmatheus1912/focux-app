import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/platform/focux_platform.dart';

void main() {
  test('FocuxPlatform exposes canonical breakpoints', () {
    expect(FocuxPlatform.compactWidth, 390);
    expect(FocuxPlatform.desktopMaxContent, 960);
    expect(FocuxPlatform.version, isNotEmpty);
  });

  test('platform sources and module layouts exist', () {
    for (final path in FocuxPlatform.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    for (final path in FocuxPlatform.moduleLayouts) {
      expect(File(path).existsSync(), isTrue, reason: 'Layout ausente: $path');
    }
  });

  testWidgets('isCompact respects viewport width', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(360, 800)),
        child: Builder(
          builder: (context) {
            expect(FocuxPlatform.isCompact(context), isTrue);
            return const SizedBox();
          },
        ),
      ),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(420, 800)),
        child: Builder(
          builder: (context) {
            expect(FocuxPlatform.isCompact(context), isFalse);
            return const SizedBox();
          },
        ),
      ),
    );
  });

  test('shells use FocuxPlatform helpers', () {
    for (final path in [
      'lib/core/screens/main_shell.dart',
      'lib/core/screens/aluno_shell.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('FocuxPlatform'));
      expect(source, contains('isCompact'));
    }
  });

  test('page transitions registered for all TargetPlatform values', () {
    final source =
        File('lib/core/theme/fx_page_transitions_builder.dart').readAsStringSync();
    for (final platform in [
      'android',
      'iOS',
      'linux',
      'macOS',
      'windows',
      'fuchsia',
    ]) {
      expect(source, contains('TargetPlatform.$platform'));
    }
  });
}
