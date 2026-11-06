import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/auth/session_invalidator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logout tira as preferências da conta e deixa as do aparelho', () async {
    SharedPreferences.setMockInitialValues({
      'saude_escolha_compartilhamento_feita': true,
      'last_exercise_prescription_v1': '{}',
      'biblioteca_bootstrap_v1_done': true,
      'focux_appearance_mode': 'dark',
    });
    FlutterSecureStorage.setMockInitialValues({});

    await SessionInvalidator.invalidate(reason: 'teste');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('saude_escolha_compartilhamento_feita'), isFalse);
    expect(prefs.containsKey('last_exercise_prescription_v1'), isFalse);
    expect(prefs.containsKey('biblioteca_bootstrap_v1_done'), isFalse);
    expect(prefs.getString('focux_appearance_mode'), 'dark');
  });

  /// Chave renomeada no código e esquecida aqui volta a vazar para o próximo
  /// usuário do aparelho.
  test('toda chave limpa no logout ainda existe no código', () {
    final fontes = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where(
          (f) =>
              !f.path
                  .replaceAll(r'\', '/')
                  .endsWith('core/auth/session_invalidator.dart'),
        )
        .map((f) => f.readAsStringSync())
        .join('\n');
    final orfas =
        SessionInvalidator.sessionPrefKeys
            .where((k) => !fontes.contains("'$k'"))
            .toList();
    expect(orfas, isEmpty);
  });
}
