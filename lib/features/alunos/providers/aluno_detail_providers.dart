import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/a11y_announce.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../avaliacao/data/avaliacao_repository.dart';
import '../../dashboard/data/command_center_data.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../health/data/health_repository.dart';
import '../../ia/data/ia_repository.dart';
import '../data/aluno_copilot_ia_cache_store.dart';
import '../data/aluno_operacao_focus_store.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_copilot_logic.dart';
import '../utils/aluno360_operacao_logic.dart';
import 'alunos_provider.dart';

final aluno360Provider = FutureProvider.family<Aluno360, int>((ref, alunoId) async {
  return AlunoRepository(ref.read(apiClientProvider)).buscarAluno360(alunoId);
});

final alunoRecoveryProvider = FutureProvider.family<RecoverySnapshot?, int>((
  ref,
  alunoId,
) async {
  final bundled = ref.watch(aluno360Provider(alunoId)).valueOrNull?.recoverySnapshot;
  if (bundled != null) return bundled;
  return HealthRepository.fromClient(
    ref.read(apiClientProvider),
  ).fetchRecoveryForAluno(alunoId);
});

/// When true, copilot card loads IA via [alunoCopilotoActionProvider] (refresh).
final alunoCopilotoForceIaProvider = StateProvider.family<bool, int>(
  (ref, alunoId) => false,
);

/// True while Aluno 360 is creating a Command Center task (disables sticky CTA).
final alunoCopilotCreatingProvider = StateProvider.family<bool, int>(
  (ref, alunoId) => false,
);

/// Operação tab focus mode — hides secondary diagnostics (status grid, wearable, quick actions).
final alunoOperacaoFocusModeProvider =
    StateNotifierProvider.family<AlunoOperacaoFocusModeController, bool, int>(
  (ref, alunoId) => AlunoOperacaoFocusModeController(ref, alunoId),
);

class AlunoOperacaoFocusModeController extends StateNotifier<bool> {
  AlunoOperacaoFocusModeController(this._ref, this.alunoId) : super(false);

  final Ref _ref;
  final int alunoId;

  /// Server preference wins, then local explicit, then contact-priority auto-default.
  Future<void> syncFromAluno(
    Aluno aluno, {
    required bool autoDefault,
  }) async {
    try {
      final server = aluno.operacaoFocusMode;
      if (server != null) {
        if (state != server) state = server;
        await AlunoOperacaoFocusStore.saveExplicit(alunoId, server);
        return;
      }
      await syncAutoDefault(autoDefault: autoDefault);
    } catch (_) {}
  }

  /// Applies contact-priority auto-default unless the personal toggled focus manually.
  Future<void> syncAutoDefault({required bool autoDefault}) async {
    try {
      final explicit = await AlunoOperacaoFocusStore.loadExplicit(alunoId);
      final next = explicit ?? autoDefault;
      if (state != next) state = next;
    } catch (_) {}
  }

  Future<void> setFocus(bool value) async {
    if (state == value) return;
    state = value;
    try {
      await AlunoOperacaoFocusStore.saveExplicit(alunoId, value);
      await AlunoRepository(_ref.read(apiClientProvider))
          .atualizarOperacaoFocus(alunoId, focusMode: value);
    } catch (_) {}
    fxAnnounceGlobal(
      value ? 'Modo foco ativado' : 'Modo foco desativado',
    );
  }

  Future<void> toggle() async => setFocus(!state);
}

/// Bust IA cache on explicit refresh (see copilot refresh button).
final alunoCopilotIaSkipCacheProvider = StateProvider.family<bool, int>(
  (ref, alunoId) => false,
);

/// True while the user-triggered IA refresh is in flight (incl. stale-while-revalidate).
final alunoCopilotIaRefreshingProvider = StateProvider.family<bool, int>(
  (ref, alunoId) => false,
);

final alunoCopilotoActionProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, alunoId) async {
      final skipCache = ref.watch(alunoCopilotIaSkipCacheProvider(alunoId));
      if (!skipCache) {
        final cached = await AlunoCopilotIaCacheStore.loadIfFresh(alunoId);
        if (cached != null) return cached;
      }
      final payload =
          await IaRepository(ref.read(apiClientProvider)).proximaAcao(alunoId);
      await AlunoCopilotIaCacheStore.save(alunoId, payload);
      ref.read(alunoCopilotIaSkipCacheProvider(alunoId).notifier).state = false;
      return payload;
    });

/// Unified Operação snapshot (sticky + copilot + outreach).
final aluno360OperacaoProvider =
    Provider.family<Aluno360OperacaoSnapshot?, int>((ref, alunoId) {
      final bundle = ref.watch(aluno360Provider(alunoId)).valueOrNull;
      if (bundle == null) return null;
      final aluno = bundle.aluno;
      final forceIa = ref.watch(alunoCopilotoForceIaProvider(alunoId));
      final iaAsync =
          forceIa ? ref.watch(alunoCopilotoActionProvider(alunoId)) : null;
      final recovery = ref.watch(alunoRecoveryProvider(alunoId)).valueOrNull;
      final openActions =
          ref.watch(alunoOpenIaActionsProvider(alunoId)).valueOrNull ??
          const [];
      final hasOpenTask =
          findOpenCopilotTask(openActions) != null ||
          (bundle.hasOpenCopilotTask ?? false);
      final backendWearable = iaAsync?.valueOrNull?['wearableRelevant'];
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
      );
    });

final alunoMedidasResumoProvider =
    FutureProvider.family<SnapshotAvaliacao?, int>((ref, alunoId) async {
      try {
        final comparativo = await AvaliacaoRepository(
          ref.read(apiClientProvider),
        ).comparativo(alunoId);
        final atual = comparativo.atual;
        final hasData =
            atual.percGordura != null ||
            (atual.massaMuscular != null && atual.massaMuscular! > 0);
        return hasData ? atual : null;
      } catch (_) {
        return null;
      }
    });

final alunoOpenIaActionsProvider =
    FutureProvider.family<List<FilaAcaoResumo>, int>((ref, alunoId) async {
      return ref
          .read(dashboardRepositoryProvider)
          .getIaCommandActions(status: 'ABERTO', alunoId: alunoId);
    });

final alunoScoreSnapshotsProvider = FutureProvider.family<
  List<FocuxScoreSnapshotResumo>,
  int
>((ref, alunoId) async {
  return ref.read(dashboardRepositoryProvider).getFocuxScoreSnapshots(alunoId);
});

final alunoEvolucaoInteligenteProvider =
    FutureProvider.family<EvolucaoInteligente, int>((ref, alunoId) async {
      return AlunoRepository(
        ref.read(apiClientProvider),
      ).buscarEvolucaoInteligente(alunoId);
    });

final alunoTimeline360ApiProvider =
    FutureProvider.family<List<Timeline360Event>, int>((ref, alunoId) async {
      final page = await AlunoRepository(
        ref.read(apiClientProvider),
      ).buscarTimeline360Page(alunoId, limit: 80);
      return page.events;
    });

final alunoAderenciaSemanalProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, alunoId) async {
      final aluno360 = await ref.watch(aluno360Provider(alunoId).future);
      return aluno360.aderenciaSemanal.dias;
    });

/// Last weight measurements from avaliações físicas (up to 7 points, chronological).
final alunoPesoHistoricoProvider =
    FutureProvider.family<List<double>, int>((ref, alunoId) async {
      final avaliacoes = await AvaliacaoRepository(
        ref.read(apiClientProvider),
      ).listar(alunoId);

      final dated = avaliacoes
          .where((a) => a.pesoKg != null)
          .map(
            (a) => (
              date: _avaliacaoSortKey(a.avaliadoEm ?? a.criadoEm),
              peso: a.pesoKg!,
            ),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final series = dated.map((e) => e.peso).toList();
      if (series.length <= 7) return series;
      return series.sublist(series.length - 7);
    });

DateTime _avaliacaoSortKey(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

Future<void> invalidateAluno360Providers(WidgetRef ref, int alunoId) async {
  ref.invalidate(aluno360Provider(alunoId));
  ref.invalidate(alunoProvider(alunoId));
  ref.invalidate(alunoRecoveryProvider(alunoId));
  ref.invalidate(alunoAutonomiaEventosProvider(alunoId));
  ref.invalidate(alunoAutonomiaResumoProvider(alunoId));
  ref.invalidate(alunoScoreSnapshotsProvider(alunoId));
  ref.invalidate(alunoEvolucaoInteligenteProvider(alunoId));
  ref.invalidate(alunoTimeline360ApiProvider(alunoId));
  ref.read(alunoCopilotoForceIaProvider(alunoId).notifier).state = false;
  ref.read(alunoCopilotIaSkipCacheProvider(alunoId).notifier).state = false;
  ref.read(alunoCopilotIaRefreshingProvider(alunoId).notifier).state = false;
  ref.invalidate(alunoCopilotoActionProvider(alunoId));
  ref.invalidate(alunoOpenIaActionsProvider(alunoId));
  ref.invalidate(alunoMedidasResumoProvider(alunoId));
  ref.invalidate(alunoAderenciaSemanalProvider(alunoId));
  ref.invalidate(alunoPesoHistoricoProvider(alunoId));
  await ref.read(aluno360Provider(alunoId).future);
}
