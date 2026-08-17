import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/aluno_repository.dart';

/// Whether Aluno Detail should subscribe to [alunoProvider] as GET /alunos/{id}
/// fallback. First paint uses only `/360`; fallback runs only when 360 failed
/// with no usable payload.
bool shouldWatchAlunoDetailFallback(AsyncValue<Aluno360> aluno360Async) {
  return aluno360Async.hasError && !aluno360Async.hasValue;
}

/// Resolves the aluno shown on Aluno Detail: prefer the 360 payload, else the
/// optional [alunoFallbackAsync] from [alunoProvider].
AsyncValue<Aluno> resolveAlunoDetailAlunoAsync({
  required AsyncValue<Aluno360> aluno360Async,
  AsyncValue<Aluno>? alunoFallbackAsync,
}) {
  if (aluno360Async.hasValue) {
    return AsyncData(aluno360Async.value!.aluno);
  }
  if (aluno360Async.hasError) {
    return alunoFallbackAsync ??
        AsyncError(aluno360Async.error!, aluno360Async.stackTrace!);
  }
  return const AsyncLoading();
}
