import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;

/// Estado simples (filtro, flag, cor) sem regra própria.
class FxValueNotifier<T> extends Notifier<T> {
  FxValueNotifier(this._initial);

  final T _initial;

  @override
  T build() => _initial;

  T get value => state;

  set value(T next) => state = next;

  bool get mounted => ref.mounted;
}

typedef FxValueProvider<T> = NotifierProvider<FxValueNotifier<T>, T>;

FxValueProvider<T> fxValueProvider<T>(T initial) =>
    NotifierProvider<FxValueNotifier<T>, T>(() => FxValueNotifier<T>(initial));

/// Flag efêmera por id (ex.: aluno) — some quando a tela sai.
NotifierProviderFamily<FxValueNotifier<T>, T, int> fxValueAutoDisposeFamily<T>(
  T initial,
) => NotifierProvider.autoDispose.family<FxValueNotifier<T>, T, int>(
  (_) => FxValueNotifier<T>(initial),
);
