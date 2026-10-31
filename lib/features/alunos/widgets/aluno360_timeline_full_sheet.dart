import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_timeline360_paged_provider.dart';
import '../utils/aluno360_timeline_logic.dart';
import 'aluno360_timeline_card.dart';
import 'aluno360_timeline_sheet_motion.dart';

/// Full Histórico 360 sheet with cursor pagination (load-more).
class Aluno360TimelineFullSheet extends ConsumerStatefulWidget {
  const Aluno360TimelineFullSheet({
    super.key,
    required this.aluno,
    required this.isDark,
    required this.primary,
  });

  final Aluno aluno;
  final bool isDark;
  final Color primary;

  @override
  ConsumerState<Aluno360TimelineFullSheet> createState() =>
      _Aluno360TimelineFullSheetState();
}

class _Aluno360TimelineFullSheetState
    extends ConsumerState<Aluno360TimelineFullSheet> {
  String? _tipo;

  List<Timeline360Item> _itemsFromEvents(List<Timeline360Event> events) {
    final mapped =
        events
            .map(
              (e) => Aluno360TimelineCard.itemFromApi(
                e,
                primary: widget.primary,
              ),
            )
            .toList();
    final filtered = mapped
        .where(
          (item) =>
              !isSmokeTimelineContent(item.body) &&
              !timeline360EhVisualizacao(kind: item.kind, body: item.body) &&
              !timeline360EhEcoDoTreino(kind: item.kind, body: item.body),
        )
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
  Widget build(BuildContext context) {
    final aluno = widget.aluno;
    final isDark = widget.isDark;
    final primary = widget.primary;
    final tipo = _tipo;
    final provider =
        tipo == null
            ? alunoTimeline360PagedProvider(aluno.id)
            : alunoTimeline360FiltradoProvider((alunoId: aluno.id, tipo: tipo));
    final pagedAsync = ref.watch(provider);
    final maxHeight =
        MediaQuery.sizeOf(context).height *
        FxHomeSheetChrome.expandHeightFactor;
    String? headerSubtitle;
    if (pagedAsync.hasValue) {
      final state = pagedAsync.requireValue;
      final items = _itemsFromEvents(state.events);
      // Se algo foi escondido (ex.: visualizações do aluno), o total do servidor
      // não vale mais: conta só o que o personal vê.
      final nadaEscondido = state.events.length == items.length;
      headerSubtitle = state.totalCount > 0 && nadaEscondido
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
            title: 'Histórico',
            subtitle: headerSubtitle,
            leading: Icon(Icons.timeline_rounded, color: primary, size: 18),
          ),
          SizedBox(height: TokensStrip.s3),
          FxChoiceStrip<String?>(
            itens: [
              for (final filtro in timeline360Filtros.entries)
                FxChoiceItem(value: filtro.key, label: filtro.value),
            ],
            selecionado: _tipo,
            onSelecionar: (tipo) => setState(() => _tipo = tipo),
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
                    onRetry: () => ref.read(provider.notifier).refresh(),
                    title: 'Não conseguimos carregar o histórico',
                  ),
              data: (state) {
                final items = _itemsFromEvents(state.events);
                final automatico =
                    state.events.length < timeline360RolagemAutomatica;
                final comBotao = state.hasMore && !automatico;
                if (items.isEmpty && !state.hasMore) {
                  return FxEmptyState(
                    icon: 'trend',
                    title: 'Nada neste filtro',
                    subtitle: 'Escolha outro filtro para ver mais sinais.',
                  );
                }
                final linhas = <Timeline360Item?>[];
                final dias = <int, String>{};
                String? atual;
                for (final item in items) {
                  final dia = timeline360DiaLabel(item.at);
                  if (dia != atual) {
                    dias[linhas.length] = dia;
                    linhas.add(null);
                    atual = dia;
                  }
                  linhas.add(item);
                }
                final rodape = state.loadingMore || comBotao ? 1 : 0;
                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (!automatico ||
                        notification.metrics.pixels <
                            notification.metrics.maxScrollExtent - 120) {
                      return false;
                    }
                    ref.read(provider.notifier).loadMore();
                    return false;
                  },
                  child: ListView.builder(
                    itemCount: linhas.length + rodape,
                    itemBuilder: (context, index) {
                      if (index >= linhas.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child:
                                state.loadingMore
                                    ? const FxLoading(size: 22, strokeWidth: 2)
                                    : FxActionLink(
                                      label: 'Carregar mais',
                                      onTap:
                                          () =>
                                              ref
                                                  .read(provider.notifier)
                                                  .loadMore(),
                                    ),
                          ),
                        );
                      }
                      final item = linhas[index];
                      if (item == null) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                            TokensStrip.s3,
                            TokensStrip.s3,
                            TokensStrip.s3,
                            TokensStrip.s1,
                          ),
                          child: DashboardSectionHeader(title: dias[index]!),
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
                            item: item,
                            isDark: isDark,
                            accent: primary,
                            alunoFirstName: aluno.nome.split(' ').first,
                            showSpineBelow:
                                index < linhas.length - 1 &&
                                linhas[index + 1] != null,
                            inkWell: true,
                            soHora: true,
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
                                  alunoId: aluno.id,
                                );
                              });
                            },
                            onRouteTap: (tileContext, item) {
                              final link = resolveTimeline360DeepLinkForPersonal(
                                link: item.deepLink,
                                alunoId: aluno.id,
                              );
                              if (link.isEmpty) return;
                              final host = context;
                              Navigator.of(tileContext).pop();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!host.mounted) return;
                                host.push(link);
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
