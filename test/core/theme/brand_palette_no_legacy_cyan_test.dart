import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garante que softs/hex da marca antiga (cyan) não voltem na UI.
/// Legado só em brand_palette / design_tokens (reset de perfil).
void main() {
  final forbidden = RegExp(
    r'0xFF13C2C2|0xFF1EC8C8|0xFF22D3EE|0xFF9DE8E8|0xFFD4F5F5|'
    r'0xFFEAF8F8|0xFFE8F8FA|0xFF00BFA5|0xFF26A69A|'
    r'#13C2C2|#1EC8C8|#22D3EE|#9DE8E8|#D4F5F5|#EAF8F8|#E8F8FA',
    caseSensitive: false,
  );

  const allowlist = {
    'lib/core/theme/brand_palette.dart',
    'lib/core/theme/design_tokens.dart',
  };

  test('lib não usa hex cyan legado fora do allowlist de reset', () {
    final hits = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final rel = entity.path.replaceAll('\\', '/');
      if (allowlist.contains(rel)) continue;
      final source = entity.readAsStringSync();
      for (final match in forbidden.allMatches(source)) {
        // Comentários que documentam o legado são ok se citam o hex
        // só em comentário de linha — ainda assim preferimos zero.
        final lineStart = source.lastIndexOf('\n', match.start) + 1;
        final lineEnd = source.indexOf('\n', match.start);
        final line = source.substring(
          lineStart,
          lineEnd == -1 ? source.length : lineEnd,
        );
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;
        hits.add('$rel: ${match.group(0)}');
      }
    }
    expect(
      hits,
      isEmpty,
      reason: 'Hex cyan legado em UI:\n${hits.join('\n')}',
    );
  });

  test('tokens_strip soft fills são azul petróleo', () {
    final source = File('lib/core/theme/tokens_strip.dart').readAsStringSync();
    expect(source, contains('0xFFEBF4F6'));
    expect(source, contains('0xFFD5E8EC'));
    expect(source, contains('0xFF9ECAD4'));
    expect(source, isNot(contains('0xFF9DE8E8')));
    expect(source, isNot(contains('0xFFD4F5F5')));
  });
}
