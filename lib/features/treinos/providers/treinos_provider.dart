import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/treino_repository.dart';

class TreinosHomeQuery {
  const TreinosHomeQuery({this.q = ''});

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

class TreinosHomeTailNotifier extends StateNotifier<TreinosHomeTailState> {
  TreinosHomeTailNotifier() : super(const TreinosHomeTailState());

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
      state = TreinosHomeTailState(
        nextPage: state.nextPage + 1,
        treinos: [...state.treinos, ...chunk.treinos],
        hasNext: chunk.hasNext,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }
}

final treinoRepositoryProvider = Provider<TreinoRepository>(
  (ref) => TreinoRepository(ref.read(apiClientProvider)),
);

final treinosHomeQueryProvider = StateProvider<TreinosHomeQuery>(
  (ref) => const TreinosHomeQuery(),
);

final treinosHomeTailProvider =
    StateNotifierProvider<TreinosHomeTailNotifier, TreinosHomeTailState>((ref) {
      ref.watch(treinosHomeQueryProvider);
      return TreinosHomeTailNotifier();
    });

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

final treinosDoAlunoProvider = FutureProvider.family<List<Treino>, int>((
  ref,
  alunoId,
) async {
  return ref.watch(treinoRepositoryProvider).listarTreinosDoAluno(alunoId);
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
