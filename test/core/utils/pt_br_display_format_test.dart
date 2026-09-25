import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/pt_br_display.dart';

void main() {
  test('decimal BR usa vírgula e milhar com ponto', () {
    expect(formatBrDecimal(90), '90,0');
    expect(formatBrDecimal(1234.5), '1.234,5');
    expect(formatBrDecimal(-2), '-2,0');
    expect(formatBrDecimal(1.75, digits: 2), '1,75');
    expect(formatBrPercent(100), '100,0%');
    expect(formatBrKg(90), '90,0 kg');
    expect(formatBrCm(82), '82,0 cm');
  });

  test('features não exibem decimal com ponto (§8)', () {
    final offenders = <String>[];
    final pattern = RegExp(r'toStringAsFixed\([1-9]\)');
    for (final f in Directory('lib/features').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final l = lines[i];
        if (!pattern.hasMatch(l)) continue;
        if (l.contains("replaceAll('.', ',')") || l.contains('.text =')) {
          continue;
        }
        offenders.add('${f.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
