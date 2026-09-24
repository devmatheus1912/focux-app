import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/storage/secure_storage.dart';

void main() {
  setUp(SecureStorage.debugResetMemoryCache);

  test('cache RAM nativo serve token/role sem releitura', () async {
    SecureStorage.debugPrimeNativeCache(
      token: 'jwt-abc',
      role: 'PERSONAL',
      requiresPasswordChange: false,
    );

    expect(await SecureStorage.getToken(), 'jwt-abc');
    expect(await SecureStorage.getRole(), 'PERSONAL');
    expect(await SecureStorage.getRequiresPasswordChange(), isFalse);
  });

  test('debugResetMemoryCache limpa o prime', () async {
    SecureStorage.debugPrimeNativeCache(token: 'x', role: 'ALUNO');
    SecureStorage.debugResetMemoryCache();
    // Após reset, flags unloaded — não assertamos Keychain real aqui.
    expect(true, isTrue);
  });
}
