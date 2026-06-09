import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/aluno_repository.dart';

/// Paged timeline state for Histórico 360 (load-more).
class Timeline360PagedState {
  const Timeline360PagedState({
    required this.events,
    this.hasMore = false,
    this.nextOffset,
    this.totalCount = 0,
    this.loadingMore = false,
  });

  final List<Timeline360Event> events;
  final bool hasMore;
  final int? nextOffset;
  final int totalCount;
  final bool loadingMore;

  Timeline360PagedState copyWith({
    List<Timeline360Event>? events,
    bool? hasMore,
    int? nextOffset,
    int? totalCount,
    bool? loadingMore,
  }) {
    return Timeline360PagedState(
      events: events ?? this.events,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      totalCount: totalCount ?? this.totalCount,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

class Timeline360PagedNotifier
    extends StateNotifier<AsyncValue<Timeline360PagedState>> {
  Timeline360PagedNotifier(this._ref, this.alunoId)
    : super(const AsyncValue.loading());

  final Ref _ref;
  final int alunoId;
  static const int _pageSize = 40;

  AlunoRepository get _repo =>
      AlunoRepository(_ref.read(apiClientProvider));

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final page = await _repo.buscarTimeline360Page(
        alunoId,
        limit: _pageSize,
        offset: 0,
      );
      state = AsyncValue.data(
        Timeline360PagedState(
          events: page.events,
          hasMore: page.hasMore,
          nextOffset: page.nextOffset,
          totalCount: page.totalCount > 0
              ? page.totalCount
              : page.events.length,
        ),
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;
    final offset = current.nextOffset ?? current.events.length;
    state = AsyncValue.data(current.copyWith(loadingMore: true));
    try {
      final page = await _repo.buscarTimeline360Page(
        alunoId,
        limit: _pageSize,
        offset: offset,
      );
      state = AsyncValue.data(
        Timeline360PagedState(
          events: [...current.events, ...page.events],
          hasMore: page.hasMore,
          nextOffset: page.nextOffset,
          totalCount: page.totalCount > 0
              ? page.totalCount
              : current.events.length + page.events.length,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(current.copyWith(loadingMore: false));
    }
  }
}

final alunoTimeline360PagedProvider = StateNotifierProvider.autoDispose
    .family<Timeline360PagedNotifier, AsyncValue<Timeline360PagedState>, int>(
      (ref, alunoId) {
        final notifier = Timeline360PagedNotifier(ref, alunoId);
        notifier.refresh();
        return notifier;
      },
    );

/// Backwards-compatible event list for Evolução tab.
final alunoTimeline360ApiProvider =
    Provider.family<AsyncValue<List<Timeline360Event>>, int>((ref, alunoId) {
      final paged = ref.watch(alunoTimeline360PagedProvider(alunoId));
      return paged.when(
        data: (state) => AsyncValue.data(state.events),
        loading: () => const AsyncValue.loading(),
        error: AsyncValue.error,
      );
    });
