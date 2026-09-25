import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../avaliacao/data/avaliacao_repository.dart';
import '../../dashboard/data/command_center_data.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../health/data/health_repository.dart';
import '../../ia/data/ia_repository.dart';
import '../../ia/models/ia_copilot_proxima_acao.dart';
import '../data/aluno_copilot_ia_cache_store.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_copilot_logic.dart';
import '../utils/aluno360_client_cache.dart';
import '../../evolucao/utils/evolucao_home_client_cache.dart';
import '../../evolucao/providers/evolucao_home_provider.dart';
import '../utils/aluno360_operacao_logic.dart';
import '../../../core/analytics/analytics_service.dart';
import 'package:flutter/foundation.dart';
import 'aluno_timeline360_paged_provider.dart';
import 'alunos_provider.dart';
import '../../../core/utils/pt_br_display.dart';

export 'aluno_timeline360_paged_provider.dart';

/// Critical path — GET `/api/alunos/{id}/360/operacao` only.
final aluno360OperacaoBundleProvider =
    FutureProvider.family<Aluno360Operacao, int>((ref, alunoId) async {
  final cached = Aluno360ClientCache.getOperacaoIfFresh(alunoId);
  if (cached != null) {
    if (kDebugMode) {
      debugPrint(
        '[aluno360] operacao cache-hit id=$alunoId '
        'age<=${Aluno360ClientCache.ttl.inSeconds}s',
      );
    }
    return cached;
  }

  // Stale-while-revalidate: reopen within 5min paints instantly, refresh idle.
  final stale = Aluno360ClientCache.getOperacaoEvenIfStale(alunoId);
  if (stale != null) {
    if (Aluno360ClientCache.claimOperacaoRefresh(alunoId)) {
      // ignore: unawaited_futures
      Future(() async {
        try {
          final bundle = await AlunoRepository(
            ref.read(apiClientProvider),
          ).buscarAluno360Operacao(alunoId);
          Aluno360ClientCache.putOperacao(alunoId, bundle);
          ref.invalidateSelf();
        } catch (_) {
          // Keep stale paint; next open retries.
        } finally {
          Aluno360ClientCache.releaseOperacaoRefresh(alunoId);
        }
      });
    }
    if (kDebugMode) {
      debugPrint('[aluno360] operacao stale-hit id=$alunoId (refreshing)');
    }
    return stale;
  }

  final sw = Stopwatch()..start();
  final bundle = await AlunoRepository(
    ref.read(apiClientProvider),
  ).buscarAluno360Operacao(alunoId);
  sw.stop();
  Aluno360ClientCache.putOperacao(alunoId, bundle);
  final ms = sw.elapsedMilliseconds;
  if (kDebugMode) {
    debugPrint('[aluno360] GET /api/alunos/$alunoId/360/operacao ${ms}ms');
  }
  // ignore: unawaited_futures
  AnalyticsService.instance.track(
    ProductEvents.aluno360FetchDuration,
    props: {
      'alunoId': alunoId,
      'durationMs': ms,
      'source': 'network',
      'endpoint': 'operacao',
    },
  );
  return bundle;
});

/// Prefetch / lazy — GET `/api/alunos/{id}/360/evolucao`.
final aluno360EvolucaoBundleProvider =
    FutureProvider.family<Aluno360Evolucao, int>((ref, alunoId) async {
  final cached = Aluno360ClientCache.getEvolucaoIfFresh(alunoId);
  if (cached != null) return cached;
  final sw = Stopwatch()..start();
  final bundle = await AlunoRepository(
    ref.read(apiClientProvider),
  ).buscarAluno360Evolucao(alunoId);
  sw.stop();
  Aluno360ClientCache.putEvolucao(alunoId, bundle);
  if (kDebugMode) {
    debugPrint(
      '[aluno360] GET /api/alunos/$alunoId/360/evolucao '
      '${sw.elapsedMilliseconds}ms',
    );
  }
  return bundle;
});

/// Prefetch / lazy — GET `/api/alunos/{id}/360/ferramentas`.
final aluno360FerramentasBundleProvider =
    FutureProvider.family<Aluno360Ferramentas, int>((ref, alunoId) async {
  final cached = Aluno360ClientCache.getFerramentasIfFresh(alunoId);
  if (cached != null) {
    _hydrateEvolucaoHomeFromFerramentas(alunoId, cached);
    return cached;
  }
  final sw = Stopwatch()..start();
  final bundle = await AlunoRepository(
    ref.read(apiClientProvider),
  ).buscarAluno360Ferramentas(alunoId);
  sw.stop();
  Aluno360ClientCache.putFerramentas(alunoId, bundle);
  _hydrateEvolucaoHomeFromFerramentas(alunoId, bundle);
  if (kDebugMode) {
    debugPrint(
      '[aluno360] GET /api/alunos/$alunoId/360/ferramentas '
      '${sw.elapsedMilliseconds}ms'
      '${bundle.evolucaoHome != null ? ' +evolucaoHome' : ''}',
    );
  }
  return bundle;
});

/// Seed Medidas cache from `/360/ferramentas.evolucaoHome`.
void _hydrateEvolucaoHomeFromFerramentas(
  int alunoId,
  Aluno360Ferramentas bundle,
) {
  final home = bundle.evolucaoHome;
  if (home == null) return;
  EvolucaoHomeClientCache.put(alunoId, home);
}

/// Fire-and-forget after Operação is usable (idle / next frame).
void prefetchAluno360SecondaryTabs(WidgetRef ref, int alunoId) {
  // ignore: unawaited_futures
  ref.read(aluno360EvolucaoBundleProvider(alunoId).future);
  // ignore: unawaited_futures
  () async {
    try {
      await ref.read(aluno360FerramentasBundleProvider(alunoId).future);
      // Fallback when BE/cliente antigo não manda evolucaoHome.
      prefetchEvolucaoHome(ref, alunoId);
    } catch (_) {
      prefetchEvolucaoHome(ref, alunoId);
    }
  }();
}

/// Warm Operação dos primeiros da lista — corta delay do 360 no tap.
void warmAluno360OperacaoList(WidgetRef ref, Iterable<int> alunoIds) {
  for (final id in alunoIds.take(3)) {
    // ignore: unawaited_futures
    ref.read(aluno360OperacaoBundleProvider(id).future);
  }
}

/// @Deprecated monolito `/360` — não usar no first paint.
final aluno360Provider = FutureProvider.family<Aluno360, int>((
  ref,
  alunoId,
) async {
  final cached = Aluno360ClientCache.getIfFresh(alunoId);
  if (cached != null) return cached;
  final bundle =
      await AlunoRepository(ref.read(apiClientProvider)).buscarAluno360(alunoId);
  Aluno360ClientCache.put(alunoId, bundle);
  return bundle;
});

final alunoRecoveryProvider = FutureProvider.family<RecoverySnapshot?, int>((
  ref,
  alunoId,
) async {
  try {
    final bundled =
        (await ref.watch(aluno360OperacaoBundleProvider(alunoId).future))
            .recoverySnapshot;
    if (bundled != null) return bundled;
  } catch (_) {
    // Operação failed — sidecar below.
  }
  return HealthRepository.fromClient(
    ref.read(apiClientProvider),
  ).fetchRecoveryForAluno(alunoId);
});

/// When true, copilot card loads IA via [alunoCopilotoActionProvider] (refresh).
final alunoCopilotoForceIaProvider = StateProvider.autoDispose.family<bool, int>(
  (ref, alunoId) => false,
);

/// True while Aluno 360 is creating a Command Center task (disables sticky CTA).
final alunoCopilotCreatingProvider = StateProvider.autoDispose.family<bool, int>(
  (ref, alunoId) => false,
);

/// Bust IA cache on explicit refresh (see copilot refresh button).
final alunoCopilotIaSkipCacheProvider =
    StateProvider.autoDispose.family<bool, int>((ref, alunoId) => false);

/// True while the user-triggered IA refresh is in flight (incl. stale-while-revalidate).
final alunoCopilotIaRefreshingProvider =
    StateProvider.autoDispose.family<bool, int>((ref, alunoId) => false);

final alunoCopilotoActionProvider =
    FutureProvider.family<IaCopilotProximaAcao, int>((ref, alunoId) async {
      final skipCache = ref.watch(alunoCopilotIaSkipCacheProvider(alunoId));
      if (!skipCache) {
        final cached = await AlunoCopilotIaCacheStore.loadIfFresh(alunoId);
        if (cached != null) return cached;
      }
      final payload = await IaRepository(
        ref.read(apiClientProvider),
      ).proximaAcao(alunoId);
      await AlunoCopilotIaCacheStore.save(alunoId, payload);
      ref.read(alunoCopilotIaSkipCacheProvider(alunoId).notifier).state = false;
      return payload;
    });

/// Unified Operação snapshot (sticky + copilot + outreach).
final aluno360OperacaoProvider =
    Provider.family<Aluno360OperacaoSnapshot?, int>((ref, alunoId) {
      final bundle = ref.watch(aluno360OperacaoBundleProvider(alunoId)).valueOrNull;
      if (bundle == null) return null;
      final aluno = bundle.aluno;
      final forceIa = ref.watch(alunoCopilotoForceIaProvider(alunoId));
      final iaAsync =
          forceIa ? ref.watch(alunoCopilotoActionProvider(alunoId)) : null;
      // Bundle-only on Operação — no recovery/open-IA sidecars after /360/operacao.
      final recovery = bundle.recoverySnapshot;
      final openActions = bundle.openCopilotTasks ?? const <FilaAcaoResumo>[];
      final hasOpenTask =
          findOpenCopilotTask(openActions) != null ||
          (bundle.hasOpenCopilotTask ?? false);
      final backendWearable = iaAsync?.valueOrNull?.wearableRelevant;
      final bundledWearable = bundle.hasWearableHistory;
      final wearableRelevant =
          backendWearable is bool
              ? backendWearable
              : (bundledWearable ?? alunoTemHistoricoWearable(recovery));
      return resolveAluno360OperacaoSnapshot(
        aluno: aluno,
        proximaAcao360: bundle.proximaAcao,
        forceIa: forceIa,
        iaAsync: iaAsync,
        hasOpenTask: hasOpenTask,
        followUpDue: isAlunoFollowUpDue(aluno),
        wearableRelevant: wearableRelevant,
        uiHints: bundle.operacaoUiHints,
      );
    });

final alunoOpenIaActionsProvider =
    FutureProvider.family<List<FilaAcaoResumo>, int>((ref, alunoId) async {
      try {
        final bundle =
            await ref.watch(aluno360OperacaoBundleProvider(alunoId).future);
        if (bundle.openCopilotTasks != null) {
          return bundle.openCopilotTasks!;
        }
      } catch (_) {
        // Operação falhou ou payload antigo — sidecar abaixo (nunca no first paint).
      }
      return ref
          .read(dashboardRepositoryProvider)
          .getIaCommandActions(status: 'ABERTO', alunoId: alunoId);
    });

final alunoEvolucaoInteligenteProvider =
    FutureProvider.family<EvolucaoInteligente, int>((ref, alunoId) async {
      final raw = await AlunoRepository(
        ref.read(apiClientProvider),
      ).buscarEvolucaoInteligente(alunoId);
      if (_hasUltimoPr(raw)) return raw;

      // Preferir recordes de evolucaoHome quando o sinal inteligente ainda
      // não trouxe último PR (ex.: PR gravado no concluir, cache antigo).
      final cached = EvolucaoHomeClientCache.getIfFresh(alunoId);
      final recordes = cached?.recordes;
      if (recordes == null || recordes.isEmpty) return raw;
      final pr = recordes.first;
      final carga = pr.cargaKg;
      return EvolucaoInteligente(
        sinal: raw.sinal,
        resumo: raw.resumo,
        ultimoPrLabel:
            carga == null
                ? pr.exercicioNome
                : '${carga == carga.roundToDouble() ? carga.toStringAsFixed(0) : formatBrDecimal(carga)}kg',
        ultimoPrCargaKg: carga,
        ultimoPrExercicio: pr.exercicioNome,
        volumeSemanal: raw.volumeSemanal,
        volumeMensal: raw.volumeMensal,
        tendenciaVolumePct: raw.tendenciaVolumePct,
        proximaAcao: raw.proximaAcao,
        sugerirCopiloto: raw.sugerirCopiloto,
        volumePorSemana: raw.volumePorSemana,
      );
    });

bool _hasUltimoPr(EvolucaoInteligente ev) {
  final label = ev.ultimoPrLabel?.trim();
  if (label != null && label.isNotEmpty) return true;
  final carga = ev.ultimoPrCargaKg;
  return carga != null && carga > 0;
}

final alunoAderenciaSemanalProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((
      ref,
      alunoId,
    ) async {
      try {
        final operacao =
            await ref.watch(aluno360OperacaoBundleProvider(alunoId).future);
        return operacao.aderenciaSemanal.diasMaps;
      } catch (_) {
        final ferramentas =
            await ref.watch(aluno360FerramentasBundleProvider(alunoId).future);
        return ferramentas.aderenciaSemanal?.diasMaps ?? const [];
      }
    });

/// Last weight measurements from avaliações físicas (up to 7 points, chronological).
final alunoPesoHistoricoProvider = FutureProvider.family<List<double>, int>((
  ref,
  alunoId,
) async {
  return AvaliacaoRepository(
    ref.read(apiClientProvider),
  ).listarPesoHistorico(alunoId);
});

Future<void> invalidateAluno360Providers(WidgetRef ref, int alunoId) async {
  Aluno360ClientCache.invalidate(alunoId);
  EvolucaoHomeClientCache.invalidate(alunoId);
  ref.invalidate(evolucaoHomeProvider(alunoId));
  ref.invalidate(aluno360OperacaoBundleProvider(alunoId));
  ref.invalidate(aluno360EvolucaoBundleProvider(alunoId));
  ref.invalidate(aluno360FerramentasBundleProvider(alunoId));
  // Monolito /360 — só se ainda houver listener (legado).
  ref.invalidate(aluno360Provider(alunoId));
  ref.invalidate(alunoProvider(alunoId));
  ref.invalidate(alunoRecoveryProvider(alunoId));
  ref.invalidate(alunoAutonomiaResumoProvider(alunoId));
  ref.invalidate(alunoEvolucaoInteligenteProvider(alunoId));
  ref.invalidate(alunoTimeline360PagedProvider(alunoId));
  ref.read(alunoCopilotoForceIaProvider(alunoId).notifier).state = false;
  ref.read(alunoCopilotIaSkipCacheProvider(alunoId).notifier).state = false;
  ref.read(alunoCopilotIaRefreshingProvider(alunoId).notifier).state = false;
  ref.invalidate(alunoCopilotoActionProvider(alunoId));
  ref.invalidate(alunoOpenIaActionsProvider(alunoId));
  ref.invalidate(alunoAderenciaSemanalProvider(alunoId));
  ref.invalidate(alunoPesoHistoricoProvider(alunoId));
  await ref.read(aluno360OperacaoBundleProvider(alunoId).future);
}

