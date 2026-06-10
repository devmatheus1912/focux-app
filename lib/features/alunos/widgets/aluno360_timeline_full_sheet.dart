import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
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
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (ctx, controller) {
        return Aluno360TimelineSheetEntrance(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 4, 16, 0),
            child: ShellSurface(
              radius: 28,
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24 + MediaQuery.of(ctx).padding.bottom,
              ),
              child: pagedAsync.when(
                loading: () => const Center(child: FxLoading()),
                error:
                    (_, __) => Center(
                      child: Text(
                        'Não foi possível carregar o histórico.',
                        style: Aluno360Layout.captionStyle(context),
                      ),
                    ),
                data: (state) {
                  final items = _itemsFromEvents(state.events);
                  final itemCount =
                      1 + items.length + (state.loadingMore ? 1 : 0);
                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.pixels <
                          notification.metrics.maxScrollExtent - 120) {
                        return false;
                      }
                      ref
                          .read(
                            alunoTimeline360PagedProvider(aluno.id).notifier,
                          )
                          .loadMore();
                      return false;
                    },
                    child: ListView.separated(
                      controller: controller,
                      itemCount: itemCount,
                      separatorBuilder: (_, index) {
                        if (index == 0) return const SizedBox(height: 12);
                        return const SizedBox(height: 10);
                      },
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final totalLabel =
                              state.totalCount > 0
                                  ? '${state.totalCount} sinais'
                                  : '${items.length} sinais';
                          return Semantics(
                            header: true,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Histórico 360',
                                        style: Aluno360Layout.sectionTitleStyle(
                                          context,
                                          ink,
                                        ),
                                      ),
                                      Text(
                                        totalLabel,
                                        style: Aluno360Layout.captionStyle(
                                          context,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Fechar histórico',
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  icon: Icon(Icons.close_rounded, color: mute),
                                  constraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final tileIndex = index - 1;
                        if (tileIndex >= items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: FxLoading(size: 22, strokeWidth: 2),
                            ),
                          );
                        }
                        return Aluno360TimelineTileEntrance(
                          index: tileIndex,
                          child: DecoratedBox(
                            decoration:
                                Aluno360Layout.timelineModalTileDecoration(
                                  context,
                                  isDark: isDark,
                                ),
                            child: Timeline360Tile(
                              item: items[tileIndex],
                              isDark: isDark,
                              accent: primary,
                              alunoFirstName: aluno.nome.split(' ').first,
                              showSpineBelow: tileIndex < items.length - 1,
                              inkWell: true,
                              onExpandableTap: (tileContext, item) {
                                final host = context;
                                Navigator.of(tileContext).pop();
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
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
          ),
        );
      },
    );
  }
}
