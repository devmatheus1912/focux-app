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
  final jobs = <Future<void>>[];
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
    jobs.add(() async {
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
    }());
  }
  await Future.wait(jobs);
}

Future<void> _ignoreErrors(Future<dynamic> future) async {
  try {
    await future;
  } catch (_) {}
}
