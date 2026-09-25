import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/operational_metric_tile.dart';

void main() {
  test('métrica usa vidro neutro, nunca poço colorido (§2/§6)', () {
    const red = Color(0xFFD32F2F);
    for (final emphasis in OperationalMetricEmphasis.values) {
      final deco = operationalMetricDecoration(
        accent: red,
        isDark: false,
        emphasis: emphasis,
      );
      expect(deco.color, TokensStrip.glassFill(dark: false));
    }
  });

  test('campo sem borda embutido não herda o fill do tema', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      for (final m in RegExp(r'InputDecoration\(').allMatches(src)) {
        var i = m.end;
        var depth = 1;
        while (depth > 0 && i < src.length) {
          final c = src[i];
          if (c == '(') depth++;
          if (c == ')') depth--;
          i++;
        }
        final block = src.substring(m.start, i);
        if (block.contains('InputBorder.none') && !block.contains('filled:')) {
          offenders.add(f.path);
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
