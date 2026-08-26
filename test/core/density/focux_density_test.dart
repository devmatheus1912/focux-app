import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/density/focux_density.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';

void main() {
  test('FocuxDensity catalog lists density tiers', () {
    expect(FocuxDensity.tierComfortable, 'comfortable');
    expect(FocuxDensity.tierCompact, 'compact');
    expect(FocuxDensity.material, VisualDensity.compact);
    expect(FocuxDensity.version, isNotEmpty);
  });

  test('density helpers use TokensStrip scale', () {
    expect(
      FocuxDensity.listTileVerticalPadding(false),
      TokensStrip.s4,
    );
    expect(
      FocuxDensity.sectionGap(true),
      TokensStrip.s2,
    );
    expect(
      FocuxDensity.metricGap(false),
      TokensStrip.s3,
    );
  });

  test('density sources and progressive disclosure widgets exist', () {
    for (final path in FocuxDensity.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }

    final theme = File('lib/core/theme/app_theme.dart').readAsStringSync();
    expect(theme, contains('VisualDensity.compact'));

    final group =
        File('lib/core/widgets/fx_settings_group.dart').readAsStringSync();
    expect(group, contains('FxSettingsGroup'));

    final prefs =
        File('lib/features/alunos/data/aluno_list_preferences_store.dart')
            .readAsStringSync();
    expect(prefs, contains('compact'));
  });
}
