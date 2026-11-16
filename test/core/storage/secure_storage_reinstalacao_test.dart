import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/storage/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// No iOS o Keychain sobrevive à desinstalação; as preferências não. Quem
/// reinstala (ou pega o aparelho de outra pessoa) não pode entrar logado na
/// conta anterior.
void main() {
  setUp(SecureStorage.debugResetMemoryCache);

  test('primeira abertura depois de instalar apaga a sessão antiga', () async {
    FlutterSecureStorage.setMockInitialValues({
      'jwt_token': 'token-da-instalacao-anterior',
      'jwt_refresh_token': 'refresh-antigo',
      'user_role': 'PERSONAL',
    });
    SharedPreferences.setMockInitialValues({});

    await SecureStorage.limparSessaoDeInstalacaoAnterior();

    expect(await SecureStorage.getToken(), isNull);
    expect(await SecureStorage.getRefreshToken(), isNull);
  });

  test('aberturas seguintes mantêm a sessão', () async {
    FlutterSecureStorage.setMockInitialValues({'jwt_token': 'token-atual'});
    SharedPreferences.setMockInitialValues({});

    await SecureStorage.limparSessaoDeInstalacaoAnterior();
    await SecureStorage.saveToken('token-atual');
    SecureStorage.debugResetMemoryCache();
    await SecureStorage.limparSessaoDeInstalacaoAnterior();

    expect(await SecureStorage.getToken(), 'token-atual');
  });
}
