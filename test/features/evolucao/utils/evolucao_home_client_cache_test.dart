import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/utils/evolucao_home_client_cache.dart';

void main() {
  tearDown(EvolucaoHomeClientCache.clear);

  test('returns fresh entry within TTL and misses after', () {
    const bundle = EvolucaoHomeBundle(medidas: [], recordes: []);
    final now = DateTime(2026, 1, 1, 12);
    EvolucaoHomeClientCache.put(1, bundle, now: now);
    expect(EvolucaoHomeClientCache.getIfFresh(1, now: now), same(bundle));
    expect(
      EvolucaoHomeClientCache.getIfFresh(
        1,
        now: now.add(const Duration(seconds: 44)),
      ),
      same(bundle),
    );
    expect(
      EvolucaoHomeClientCache.getIfFresh(
        1,
        now: now.add(const Duration(seconds: 46)),
      ),
      isNull,
    );
  });
}
