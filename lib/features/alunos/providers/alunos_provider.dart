import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/sessao_provider.dart';
import '../../../core/state/fx_value_notifier.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../ia/providers/ia_copilot_providers.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../data/aluno_repository.dart';
import '../utils/alunos_home_client_cache.dart';
import '../utils/aluno360_client_cache.dart';

final alunoRepositoryProvider = Provider<AlunoRepository>(
  (ref) => AlunoRepository(ref.read(apiClientProvider)),
);

final alunosHomeQueryProvider = fxValueProvider<AlunosHomeQuery>(
  const AlunosHomeQuery(),
);

class AlunosHomeTailState {
  const AlunosHomeTailState({
    this.nextPage = 1,
    this.alunos = const [],
    this.hasNext = false,
    this.loading = false,
  });

  final int nextPage;
  final List<Aluno> alunos;
  final bool hasNext;
  final bool loading;

  AlunosHomeTailState copyWith({
    int? nextPage,
    List<Aluno>? alunos,
    bool? hasNext,
    bool? loading,
  }) => AlunosHomeTailState(
    nextPage: nextPage ?? this.nextPage,
    alunos: alunos ?? this.alunos,
    hasNext: hasNext ?? this.hasNext,
    loading: loading ?? this.loading,
  );
}

class AlunosHomeTailNotifier extends Notifier<AlunosHomeTailState> {
  @override
  AlunosHomeTailState build() {
    ref.watch(alunosHomeQueryProvider);
    return const AlunosHomeTailState();
  }

  void clear() {
    state = const AlunosHomeTailState();
  }

  void reset(AlunosHomePageMeta page) {
    state = AlunosHomeTailState(hasNext: page.hasNext);
  }

  Future<void> loadMore({
    required AlunosHomeQuery query,
    required AlunoRepository repo,
  }) async {
    if (state.loading || !state.hasNext) return;
    state = state.copyWith(loading: true);
    try {
      final chunk = await repo.getHome(
        page: state.nextPage,
        size: AlunosHomeQuery.pageSize,
        q: query.q,
        filtro: query.filtroApi,
        ordenacao: query.ordenacaoApi,
      );
      if (!ref.mounted) return;
      state = AlunosHomeTailState(
        nextPage: state.nextPage + 1,
        alunos: [...state.alunos, ...chunk.alunos],
        hasNext: chunk.page.hasNext,
      );
    } catch (_) {
      if (ref.mounted) state = state.copyWith(loading: false);
      rethrow;
    }
  }
}

final alunosHomeTailProvider =
    NotifierProvider<AlunosHomeTailNotifier, AlunosHomeTailState>(
      AlunosHomeTailNotifier.new,
    );

final alunosHomeProvider = FutureProvider<AlunosHomeBundle>((ref) async {
  ref.watch(sessaoProvider);
  final query = ref.watch(alunosHomeQueryProvider);
  final cached = AlunosHomeClientCache.getIfFresh(query);
  if (cached != null) return cached;
  final fresh = await ref.read(alunoRepositoryProvider).getHome(
    page: 0,
    size: AlunosHomeQuery.pageSize,
    q: query.q,
    filtro: query.filtroApi,
    ordenacao: query.ordenacaoApi,
  );
  AlunosHomeClientCache.put(query, fresh);
  final plano = fresh.planoFeatures;
  if (plano != null) {
    ref.read(planoFeaturesProvider.notifier).seedFromHome(plano);
  }
  return fresh;
});

final alunosProvider = FutureProvider<List<Aluno>>((ref) async {
  ref.watch(sessaoProvider);
  return (await ref.watch(alunosHomeProvider.future)).alunos;
});

final alunoProvider = FutureProvider.family<Aluno, int>((ref, id) async {
  ref.watch(sessaoProvider);
  return ref.read(alunoRepositoryProvider).buscar(id);
});

final alunoAutonomiaResumoProvider =
    FutureProvider.family<AlunoAutonomiaResumo, int>((ref, id) async {
      ref.watch(sessaoProvider);
      return ref.read(alunoRepositoryProvider).buscarAutonomiaResumo(id);
    });

/// Perfil do aluno autenticado (endpoint /api/aluno/me).
final alunoMeProvider = FutureProvider<Aluno>((ref) async {
  ref.watch(sessaoProvider);
  return ref.read(alunoRepositoryProvider).me();
});

/// BFF da aba Perfil — `GET /api/aluno/perfil/home`.
final alunoPerfilHomeProvider = FutureProvider<AlunoPerfilHomeBundle>((ref) async {
  ref.watch(sessaoProvider);
  return ref.read(alunoRepositoryProvider).getPerfilHome();
});

/// Lista única do que mostra a carteira: Alunos Home (e a cauda paginada),
/// 360 e Copiloto. Tela usa [invalidateAlunosCaches]; o ciclo de vida do aluno
/// lê este provider. Uma lista só, para os dois caminhos não divergirem.
final limparCachesDeAlunosProvider = Provider<void Function()>(
  (ref) => () {
    AlunosHomeClientCache.clear();
    Aluno360ClientCache.clear();
    ref.read(alunosHomeTailProvider.notifier).clear();
    ref.invalidate(alunosHomeProvider);
    ref.invalidate(iaCopilotoHomeProvider);
  },
);

void invalidateAlunosCaches(WidgetRef ref) =>
    ref.read(limparCachesDeAlunosProvider)();

/// Lista + chips — sem apagar o cache 360 de todos os alunos.
void invalidateAlunosListCaches(WidgetRef ref) {
  AlunosHomeClientCache.clear();
  ref.read(alunosHomeTailProvider.notifier).clear();
  ref.invalidate(alunosHomeProvider);
}

void invalidateAlunosListCachesRef(Ref ref) {
  AlunosHomeClientCache.clear();
  ref.read(alunosHomeTailProvider.notifier).clear();
  ref.invalidate(alunosHomeProvider);
}
