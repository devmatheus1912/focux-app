import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/fx_value_notifier.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/treino_repository.dart';

class TreinosHomeQuery {
  const TreinosHomeQuery({this.q = ''});

  final String q;

  static const pageSize = 40;
}

class TreinosAlunoQuery {
  const TreinosAlunoQuery({this.q = ''});

  final String q;

  static const pageSize = 40;
}

class TreinosHomeTailState {
  const TreinosHomeTailState({
    this.nextPage = 1,
    this.treinos = const [],
    this.hasNext = false,
    this.loading = false,
  });

  final int nextPage;
  final List<Treino> treinos;
  final bool hasNext;
  final bool loading;

  TreinosHomeTailState copyWith({
    int? nextPage,
    List<Treino>? treinos,
    bool? hasNext,
    bool? loading,
  }) => TreinosHomeTailState(
    nextPage: nextPage ?? this.nextPage,
    treinos: treinos ?? this.treinos,
    hasNext: hasNext ?? this.hasNext,
    loading: loading ?? this.loading,
  );
}

class TreinosHomeTailNotifier extends Notifier<TreinosHomeTailState> {
  TreinosHomeTailNotifier([this.alunoId]);

  /// `null` = lista geral; senão, treinos do aluno.
  final int? alunoId;

  @override
  TreinosHomeTailState build() {
    final id = alunoId;
    if (id == null) {
      ref.watch(treinosHomeQueryProvider);
    } else {
      ref.watch(treinosDoAlunoQueryProvider(id));
    }
    return const TreinosHomeTailState();
  }

  void clear() {
    state = const TreinosHomeTailState();
  }

  void reset({required bool hasNext}) {
    state = TreinosHomeTailState(hasNext: hasNext);
  }

  Future<void> loadMore({
    required TreinosHomeQuery query,
    required TreinoRepository repo,
  }) async {
    if (state.loading || !state.hasNext) return;
    state = state.copyWith(loading: true);
    try {
      final chunk = await repo.getHome(
        page: state.nextPage,
        size: TreinosHomeQuery.pageSize,
        q: query.q,
      );
      if (!ref.mounted) return;
      state = TreinosHomeTailState(
        nextPage: state.nextPage + 1,
        treinos: [...state.treinos, ...chunk.treinos],
        hasNext: chunk.hasNext,
      );
    } catch (_) {
      if (ref.mounted) state = state.copyWith(loading: false);
      rethrow;
    }
  }

  Future<void> loadMoreAluno({
    required int alunoId,
    required TreinosAlunoQuery query,
    required TreinoRepository repo,
  }) async {
    if (state.loading || !state.hasNext) return;
    state = state.copyWith(loading: true);
    try {
      final chunk = await repo.listarTreinosDoAlunoPagina(
        alunoId,
        page: state.nextPage,
        size: TreinosAlunoQuery.pageSize,
        q: query.q,
      );
      if (!ref.mounted) return;
      state = TreinosHomeTailState(
        nextPage: state.nextPage + 1,
        treinos: [...state.treinos, ...chunk.treinos],
        hasNext: chunk.hasNext,
      );
    } catch (_) {
      if (ref.mounted) state = state.copyWith(loading: false);
      rethrow;
    }
  }
}

final treinoRepositoryProvider = Provider<TreinoRepository>(
  (ref) => TreinoRepository(ref.read(apiClientProvider)),
);

final treinosHomeQueryProvider = fxValueProvider<TreinosHomeQuery>(
  const TreinosHomeQuery(),
);

final treinosHomeTailProvider =
    NotifierProvider<TreinosHomeTailNotifier, TreinosHomeTailState>(
      TreinosHomeTailNotifier.new,
    );

final treinosHomeProvider = FutureProvider<TreinosHomeBundle>((ref) async {
  final query = ref.watch(treinosHomeQueryProvider);
  return ref.watch(treinoRepositoryProvider).getHome(
    q: query.q,
    page: 0,
    size: TreinosHomeQuery.pageSize,
  );
});

final treinosProvider = FutureProvider<List<Treino>>((ref) async {
  return (await ref.watch(treinosHomeProvider.future)).treinos;
});

final treinosDoAlunoQueryProvider = NotifierProvider.family<
  FxValueNotifier<TreinosAlunoQuery>,
  TreinosAlunoQuery,
  int
>((alunoId) => FxValueNotifier(const TreinosAlunoQuery()));

final treinosDoAlunoTailProvider = NotifierProvider.family<
  TreinosHomeTailNotifier,
  TreinosHomeTailState,
  int
>(TreinosHomeTailNotifier.new);

final treinosDoAlunoPageProvider =
    FutureProvider.family<TreinosAlunoPage, int>((ref, alunoId) async {
      final query = ref.watch(treinosDoAlunoQueryProvider(alunoId));
      return ref.watch(treinoRepositoryProvider).listarTreinosDoAlunoPagina(
        alunoId,
        q: query.q,
        page: 0,
        size: TreinosAlunoQuery.pageSize,
      );
    });

final treinoProvider = FutureProvider.family<Treino, int>((ref, id) async {
  return ref.watch(treinoRepositoryProvider).buscar(id);
});

/// First paint do picker — um GET (`/api/treinos/{id}/picker/home`).
final treinoPickerHomeProvider =
    FutureProvider.family<TreinoPickerHomeBundle, int>((ref, treinoId) async {
      return ref.watch(treinoRepositoryProvider).getPickerHome(treinoId);
    });

void invalidateTreinosCaches(WidgetRef ref) {
  ref.read(treinosHomeTailProvider.notifier).clear();
  ref.invalidate(treinosHomeProvider);
}

void invalidateTreinosDoAluno(WidgetRef ref, int alunoId) {
  ref.read(treinosDoAlunoTailProvider(alunoId).notifier).clear();
  ref.invalidate(treinosDoAlunoPageProvider(alunoId));
}
