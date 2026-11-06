import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/bff_snapshot_cache.dart';

void main() {
  late BffSnapshotCache<String> cache;
  late List<Completer<String?>> respostas;
  late int construcoes;
  late FutureProvider<String> provider;

  setUp(() {
    cache = BffSnapshotCache<String>(
      etagPath: '/api/teste/home',
      ttl: const Duration(seconds: 60),
    );
    respostas = [];
    construcoes = 0;
    provider = FutureProvider<String>((ref) {
      construcoes++;
      return lerSnapshotBff(ref, cache, () {
        final c = Completer<String?>();
        respostas.add(c);
        return c.future;
      });
    });
  });

  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('stale pinta na hora e atualiza em segundo plano uma vez', () async {
    cache.put(
      'velho',
      now: DateTime.now().subtract(const Duration(minutes: 2)),
    );
    final c = container();

    expect(await c.read(provider.future), 'velho');
    await pumpEventQueue();
    expect(respostas, hasLength(1));
    respostas.single.complete('novo');
    await pumpEventQueue();

    expect(cache.getIfFresh(), 'novo');
    expect(await c.read(provider.future), 'novo');
    expect(respostas, hasLength(1));
  });

  test(
    '304 em segundo plano sem cópia nova não reconstrói o provider',
    () async {
      cache.put(
        'velho',
        now: DateTime.now().subtract(const Duration(minutes: 2)),
      );
      final c = container();

      await c.read(provider.future);
      await pumpEventQueue();
      respostas.single.complete(null);
      await pumpEventQueue();

      expect(cache.getIfFresh(), 'velho');
      expect(construcoes, 1);
    },
  );

  test(
    'resposta que chega depois de um clear não volta para o cache',
    () async {
      final c = container();
      final leitura = c.read(provider.future);
      await pumpEventQueue();

      cache.clear(); // logout no meio da busca
      respostas.single.complete('da conta anterior');
      expect(await leitura, 'da conta anterior');

      expect(cache.hasBody, isFalse);
    },
  );

  test(
    'refresh em segundo plano que perde a corrida para um clear é descartado',
    () async {
      cache.put(
        'velho',
        now: DateTime.now().subtract(const Duration(minutes: 2)),
      );
      final c = container();

      await c.read(provider.future);
      await pumpEventQueue();
      cache.clear();
      respostas.single.complete('da conta anterior');
      await pumpEventQueue();

      expect(cache.hasBody, isFalse);
    },
  );
}
