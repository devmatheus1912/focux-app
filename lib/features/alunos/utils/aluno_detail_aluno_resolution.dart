import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/aluno_repository.dart';
import 'alunos_home_client_cache.dart';

/// Whether Aluno Detail should subscribe to [alunoProvider] as GET /alunos/{id}
/// fallback. First paint uses only `/360`; fallback runs only when 360 failed
/// with no usable payload.
bool shouldWatchAlunoDetailFallback(AsyncValue<Aluno360> aluno360Async) {
  return aluno360Async.hasError && !aluno360Async.hasValue;
}

/// Recovery sidecar GET: never on first paint / Operação mount.
/// Prefer the `/360` bundle; missing recovery stays empty (no health waterfall).
bool shouldWatchAlunoRecoverySidecar(
  AsyncValue<Aluno360> aluno360Async, {
  required int tabIndex,
}) {
  return false;
}

/// Evolução / timeline sidecars: only after the Evolução tab was opened, and
/// never while `/360` is loading. Prefer bundle fields on success.
bool shouldWatchAluno360Tab1Sidecars(
  AsyncValue<Aluno360> aluno360Async, {
  required int tabIndex,
  bool evolucaoTabOpened = false,
}) {
  if (!evolucaoTabOpened || tabIndex != 1) return false;
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

/// Nome/foto/status from list navigation or home cache while `/360` loads.
Aluno? resolveAlunoDetailListPreview({
  required int alunoId,
  Aluno? routePreview,
}) {
  if (routePreview != null && routePreview.id == alunoId) {
    return routePreview;
  }
  return AlunosHomeClientCache.findAlunoById(alunoId);
}
