import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/auth/sessao_provider.dart';
import 'package:focux_app/core/auth/session_invalidator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'provider com dado do usuário refaz depois de trocar de conta',
    () async {
      var buscas = 0;
      final contaAtual = FutureProvider<int>((ref) async {
        ref.watch(sessaoProvider);
        return ++buscas;
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final sub = c.listen(contaAtual, (_, _) {});
      addTearDown(sub.close);

      expect(await c.read(contaAtual.future), 1);
      await SessionInvalidator.invalidate(reason: 'troca de conta');

      expect(await c.read(contaAtual.future), 2);
    },
  );

  /// Provider que vive o app todo e não observa a sessão mostra o dado da
  /// conta anterior depois de um logout/login sem fechar o app.
  test(
    'todo FutureProvider/StreamProvider sem autoDispose observa a sessão',
    () {
      final definicao = RegExp(
        r'^final (\w+) =\s*(?:FutureProvider|StreamProvider)(?:\.family)?<',
        multiLine: true,
      );
      final failures = <String>[];
      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final source = file.readAsStringSync();
        final defs = definicao.allMatches(source).toList();
        for (var i = 0; i < defs.length; i++) {
          final m = defs[i];
          // Até a próxima definição: a regra vale provider por provider.
          final fim = i + 1 < defs.length ? defs[i + 1].start : source.length;
          final corpo = source.substring(m.end, fim);
          if (!corpo.contains('ref.watch(sessaoProvider)')) {
            final path = file.path.replaceAll(r'\', '/');
            failures.add(
              '${path.substring(path.indexOf('lib/'))}: ${m.group(1)}',
            );
          }
        }
      }
      expect(
        failures,
        isEmpty,
        reason: 'Adicione ref.watch(sessaoProvider) ou use autoDispose.',
      );
    },
  );
}
