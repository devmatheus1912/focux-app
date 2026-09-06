import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/aluno_repository.dart';
import 'alunos_home_client_cache.dart';

/// Whether Aluno Detail should subscribe to [alunoProvider] as GET /alunos/{id}
/// fallback. First paint uses only `/360/operacao`; fallback runs only when
/// operacao failed with no usable payload.
bool shouldWatchAlunoDetailFallback(AsyncValue<Aluno360Operacao> operacaoAsync) {
  return operacaoAsync.hasError && !operacaoAsync.hasValue;
}

/// Recovery sidecar GET: never on first paint / Operação mount.
/// Prefer the `/360/operacao` bundle; missing recovery stays empty.
bool shouldWatchAlunoRecoverySidecar(
  AsyncValue<Aluno360Operacao> operacaoAsync, {
  required int tabIndex,
}) {
  return false;
}

/// Evolução granular sidecars: only after Evolução tab opened **and**
/// `/360/evolucao` failed. Prefer the evolucao bundle on success.
bool shouldWatchAluno360Tab1Sidecars(
  AsyncValue<Aluno360Evolucao> evolucaoAsync, {
  required int tabIndex,
  bool evolucaoTabOpened = false,
}) {
  if (!evolucaoTabOpened || tabIndex != 1) return false;
  if (evolucaoAsync.hasValue) return false;
  return evolucaoAsync.hasError;
}

/// Resolves the aluno shown on Aluno Detail: prefer the Operação payload,
/// else the optional [alunoFallbackAsync] from [alunoProvider].
AsyncValue<Aluno> resolveAlunoDetailAlunoAsync({
  required AsyncValue<Aluno360Operacao> operacaoAsync,
  AsyncValue<Aluno>? alunoFallbackAsync,
}) {
  if (operacaoAsync.hasValue) {
    return AsyncData(operacaoAsync.value!.aluno);
  }
  if (operacaoAsync.hasError) {
    return alunoFallbackAsync ??
        AsyncError(operacaoAsync.error!, operacaoAsync.stackTrace!);
  }
  return const AsyncLoading();
}

/// Nome/foto/status from list navigation or home cache while `/360/operacao`
/// loads — paints the shell immediately on tap.
Aluno? resolveAlunoDetailListPreview({
  required int alunoId,
  Aluno? routePreview,
}) {
  if (routePreview != null && routePreview.id == alunoId) {
    return routePreview;
  }
  return AlunosHomeClientCache.findAlunoById(alunoId);
}
