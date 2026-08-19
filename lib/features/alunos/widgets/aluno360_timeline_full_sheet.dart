import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/aluno360_timeline_logic.dart';
import 'aluno360_timeline_card.dart';
import 'aluno360_timeline_sheet_motion.dart';

/// Full Histórico 360 sheet with cursor pagination (load-more).
class Aluno360TimelineFullSheet extends ConsumerWidget {
  const Aluno360TimelineFullSheet({
    super.key,
    required this.aluno,
    required this.isDark,
    required this.primary,
  });

  final Aluno aluno;
  final bool isDark;
  final Color primary;

  List<Timeline360Item> _itemsFromEvents(List<Timeline360Event> events) {
    final mapped =
        events
            .map((e) => Aluno360TimelineCard.itemFromApi(e, primary: primary))
            .toList();
    final filtered = mapped
        .where((item) => !isSmokeTimelineContent(item.body))
        .toList(growable: false);
    return sortTimeline360Items(
      dedupeAutonomiaTimelineByTask(
        dedupeChatTimelineByFingerprint(
          filtered,
          kindOf: (item) => item.kind,
          bodyOf: (item) => item.body,
        ),
        kindOf: (item) => item.kind,
        titleOf: (item) => item.title,
      ),
      atOf: (item) => item.at,
      priorityOf: (item) => item.priority,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagedAsync = ref.watch(alunoTimeline360PagedProvider(aluno.id));
    final maxHeight =
        MediaQuery.sizeOf(context).height *
        FxHomeSheetChrome.expandHeightFactor;
    String? headerSubtitle;
    if (pagedAsync.hasValue) {
      final state = pagedAsync.requireValue;
      final items = _itemsFromEvents(state.events);
      headerSubtitle =
          state.totalCount > 0
              ? '${state.totalCount} sinais'
              : '${items.length} sinais';
    }

    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight: maxHeight,
      expand: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Histórico 360',
            subtitle: headerSubtitle,
            leading: Icon(Icons.timeline_rounded, color: primary, size: 18),
          ),
          SizedBox(height: TokensStrip.s3),
          Expanded(
            child: pagedAsync.when(
              loading: () => const SkeletonList(count: 6),
              error:
                  (e, _) => FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    message: friendlyError(
                      e,
                      fallback: 'Não foi possível carregar o histórico.',
                    ),
                    onRetry:
                        () =>
                            ref
                                .read(
                                  alunoTimeline360PagedProvider(
                                    aluno.id,
                                  ).notifier,
                                )
                                .refresh(),
                    title: 'Não conseguimos carregar o histórico',
                  ),
              data: (state) {
                final items = _itemsFromEvents(state.events);
                final itemCount = items.length + (state.loadingMore ? 1 : 0);
                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels <
                        notification.metrics.maxScrollExtent - 120) {
                      return false;
                    }
                    ref
                        .read(alunoTimeline360PagedProvider(aluno.id).notifier)
                        .loadMore();
                    return false;
                  },
                  child: ListView.separated(
                    itemCount: itemCount,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index >= items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: FxLoading(size: 22, strokeWidth: 2),
                          ),
                        );
                      }
                      return Aluno360TimelineTileEntrance(
                        index: index,
                        child: DecoratedBox(
                          decoration:
                              Aluno360Layout.timelineModalTileDecoration(
                                context,
                                isDark: isDark,
                              ),
                          child: Timeline360Tile(
                            item: items[index],
                            isDark: isDark,
                            accent: primary,
                            alunoFirstName: aluno.nome.split(' ').first,
                            showSpineBelow: index < items.length - 1,
                            inkWell: true,
                            onExpandableTap: (tileContext, item) {
                              final host = context;
                              Navigator.of(tileContext).pop();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!host.mounted) return;
                                showTimeline360BodySheet(
                                  host,
                                  item,
                                  accent: primary,
                                  isDark: isDark,
                                );
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
