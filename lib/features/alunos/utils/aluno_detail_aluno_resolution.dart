import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/aluno_repository.dart';

/// Whether Aluno Detail should subscribe to [alunoProvider] as GET /alunos/{id}
/// fallback. First paint uses only `/360`; fallback runs only when 360 failed
/// with no usable payload.
bool shouldWatchAlunoDetailFallback(AsyncValue<Aluno360> aluno360Async) {
  return aluno360Async.hasError && !aluno360Async.hasValue;
}

/// Recovery sidecar GET: never while `/360` is loading. Use the bundled
/// snapshot when present; only sidecar after 360 settled without recovery.
bool shouldWatchAlunoRecoverySidecar(
  AsyncValue<Aluno360> aluno360Async, {
  required int tabIndex,
}) {
  if (tabIndex != 0) return false;
  if (!aluno360Async.hasValue && !aluno360Async.hasError) return false;
  return aluno360Async.valueOrNull?.recoverySnapshot == null;
}

/// Evolução / timeline sidecars: not while `/360` is loading. Prefer bundle
/// fields on success; sidecar only when 360 settled without a payload.
bool shouldWatchAluno360Tab1Sidecars(
  AsyncValue<Aluno360> aluno360Async, {
  required int tabIndex,
}) {
  if (tabIndex != 1) return false;
  if (aluno360Async.hasValue) return false;
  return aluno360Async.hasError;
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
