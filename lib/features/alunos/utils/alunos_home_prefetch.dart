import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/alunos_list_filters.dart';
import '../providers/alunos_provider.dart';
import 'alunos_home_client_cache.dart';

void prefetchAlunosHome(WidgetRef ref) {
  unawaited(_ignoreErrors(ref.read(alunosHomeProvider.future)));
}

void prefetchAlunosHomeFilterVariants(
  Ref ref, {
  required AlunosHomeQuery base,
  bool includeFinanceFilter = true,
}) {
  unawaited(
    _warmFilterVariants(
      ref,
      base: base,
      includeFinanceFilter: includeFinanceFilter,
    ),
  );
}

Future<void> _warmFilterVariants(
  Ref ref, {
  required AlunosHomeQuery base,
  required bool includeFinanceFilter,
}) async {
  final repo = ref.read(alunoRepositoryProvider);
  const maxConcurrent = 2;
  final pending = <Future<void>>[];

  Future<void> enqueue(Future<void> Function() job) async {
    final run = job();
    pending.add(run);
    try {
      await run;
    } finally {
      pending.remove(run);
    }
  }

  for (final filtro in AlunoFiltro.values) {
    if (filtro == AlunoFiltro.inadimplentes && !includeFinanceFilter) {
      continue;
    }
    if (filtro == base.filtro && base.q.isEmpty) continue;
    final query = AlunosHomeQuery(
      q: base.q,
      filtro: filtro,
      ordenacao: base.ordenacao,
    );
    if (AlunosHomeClientCache.getIfFresh(query) != null) continue;

    while (pending.length >= maxConcurrent) {
      await Future.any(pending);
    }

    unawaited(
      enqueue(() async {
        try {
          final bundle = await repo.getHome(
            page: 0,
            size: AlunosHomeQuery.pageSize,
            q: query.q,
            filtro: query.filtroApi,
            ordenacao: query.ordenacaoApi,
          );
          AlunosHomeClientCache.put(query, bundle);
        } catch (_) {}
      }),
    );
  }

  if (pending.isNotEmpty) {
    await Future.wait(pending);
  }
}

Future<void> _ignoreErrors(Future<dynamic> future) async {
  try {
    await future;
  } catch (_) {}
}
