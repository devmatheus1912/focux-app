import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/utils/legacy_password_reset_redirect.dart';

void main() {
  group('legacyPasswordResetPathFromUri', () {
    test('extrai token do fragmento hash', () {
      final uri = Uri.parse(
        'https://focux-personal.vercel.app/#/resetar-senha?token=ABC123',
      );
      expect(
        legacyPasswordResetPathFromUri(uri),
        '/resetar-senha?token=ABC123',
      );
    });

    test('ignora fragmento sem reset', () {
      final uri = Uri.parse('https://focux-personal.vercel.app/#/login');
      expect(legacyPasswordResetPathFromUri(uri), isNull);
    });

    test('ignora path limpo sem fragmento', () {
      final uri = Uri.parse(
        'https://focux-personal.vercel.app/resetar-senha?token=XYZ',
      );
      expect(legacyPasswordResetPathFromUri(uri), isNull);
    });
  });
}
