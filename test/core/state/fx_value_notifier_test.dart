import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/state/fx_value_notifier.dart';

void main() {
  test('valor inicial e escrita notificam quem assiste', () {
    final provider = fxValueProvider<String>('');
    final container = ProviderContainer.test();
    final seen = <String>[];
    container.listen(provider, (_, next) => seen.add(next));

    expect(container.read(provider), '');
    container.read(provider.notifier).value = 'ana';

    expect(container.read(provider), 'ana');
    expect(seen, ['ana']);
  });

  test('flag por id isola cada aluno e volta ao padrão ao descartar', () async {
    final flag = fxValueAutoDisposeFamily<bool>(false);
    final container = ProviderContainer.test();
    final sub = container.listen(flag(1), (_, _) {});

    container.read(flag(1).notifier).value = true;
    expect(container.read(flag(1)), isTrue);
    expect(container.read(flag(2)), isFalse);

    sub.close();
    await container.pump();
    expect(container.read(flag(1)), isFalse);
  });

  test('mounted cai após o container ser descartado', () {
    final provider = fxValueProvider<int>(0);
    final container = ProviderContainer();
    final notifier = container.read(provider.notifier);
    expect(notifier.mounted, isTrue);

    container.dispose();
    expect(notifier.mounted, isFalse);
  });
}
