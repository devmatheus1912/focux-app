import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/growth/utils/migracao_texto_normalizer.dart';

void main() {
  group('MigracaoTextoNormalizer', () {
    test('não altera lista já em uma linha por aluno', () {
      const input =
          'Ana Silva ana@test.com 11999998888\n'
          'Bruno Costa bruno@test.com 21988887777';

      expect(MigracaoTextoNormalizer.normalizeForImport(input), input);
      expect(MigracaoTextoNormalizer.looksLikeFragmentedOcr(input), isFalse);
    });

    test('reagrupa OCR vertical (uma palavra por linha) por e-mail', () {
      const ocr = '''
Ana
Silva
ana@test.com
11999998888
Bruno
Costa
bruno@test.com
21988887777
''';

      expect(MigracaoTextoNormalizer.looksLikeFragmentedOcr(ocr), isTrue);

      final out = MigracaoTextoNormalizer.normalizeForImport(ocr);
      final lines = out.split('\n');

      expect(lines, hasLength(2));
      expect(lines[0], 'Ana Silva ana@test.com 11999998888');
      expect(lines[1], 'Bruno Costa bruno@test.com 21988887777');
    });

    test('sem e-mail colapsa espaços mas mantém uma linha', () {
      const ocr = '''
João
da
Silva
''';

      final out = MigracaoTextoNormalizer.normalizeForImport(ocr);
      expect(out, 'João da Silva');
    });

    test('duas linhas com nome completo não dispara heurística', () {
      const input = 'Ana Silva\nBruno Costa';
      expect(MigracaoTextoNormalizer.looksLikeFragmentedOcr(input), isFalse);
      expect(MigracaoTextoNormalizer.normalizeForImport(input), input);
    });
  });
}
