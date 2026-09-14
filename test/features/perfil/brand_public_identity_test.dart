import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/utils/brand_public_identity.dart';

void main() {
  test('suggestSlugFromNome normaliza acentos', () {
    expect(suggestSlugFromNome('Matheus Oliveira'), 'matheus-oliveira');
  });

  test('validateBrandSlug rejeita relay', () {
    expect(
      validateBrandSlug('558m7rb5yh-privaterelay-appleid-com'),
      isNotNull,
    );
    expect(validateBrandSlug('matheus-oliveira'), isNull);
  });

  test('isPrivateRelayEmail', () {
    expect(
      isPrivateRelayEmail('x@privaterelay.appleid.com'),
      isTrue,
    );
    expect(isPrivateRelayEmail('a@icloud.com'), isFalse);
  });
}
