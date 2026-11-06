import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_invalidator.dart';

/// Muda a cada logout, troca de conta ou sessão derrubada
/// ([SessionInvalidator.generation]). Provider com dado do usuário que vive o
/// app todo faz `ref.watch(sessaoProvider)`: na troca de conta ele refaz sozinho
/// em vez de mostrar o que era da conta anterior. Sem lista para esquecer.
final sessaoProvider = Provider<int>((ref) {
  void mudou() => ref.invalidateSelf();
  SessionInvalidator.listenable.addListener(mudou);
  ref.onDispose(() => SessionInvalidator.listenable.removeListener(mudou));
  return SessionInvalidator.generation;
});
