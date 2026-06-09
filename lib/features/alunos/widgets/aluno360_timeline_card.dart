import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_timeline_logic.dart';
import 'aluno360_action_empty_panel.dart';
import 'aluno360_mini_autonomy_chip.dart';
import 'aluno360_section_header.dart';
import 'aluno360_timeline_priority_badge.dart';
import 'aluno360_timeline_full_sheet.dart';
import 'aluno360_timeline_sheet_motion.dart';
import 'aluno_outreach_message_sheet.dart';

class Aluno360TimelineCard extends StatelessWidget {
  const Aluno360TimelineCard({
    super.key,
    required this.aluno,
    required this.timelineApiAsync,
    required this.isDark,
    this.compactEmpty = false,
  });

  final Aluno aluno;
  final AsyncValue<List<Timeline360Event>> timelineApiAsync;
  final bool isDark;
  final bool compactEmpty;

  static Timeline360Item itemFromApi(
    Timeline360Event e, {
    required Color primary,
  }) {
    final at = DateTime.tryParse(e.ocorridoEm);
    final tipo = e.tipo;
    IconData icon;
    Color color;
    String kind;
    switch (tipo) {
      case 'RADAR':
        icon = Icons.radar_outlined;
        color = EagleTokens.warn;
        kind = 'Radar';
        break;
      case 'CHECKIN':
        icon = Icons.fitness_center_outlined;
        color = EagleTokens.good;
        kind = 'Check-in';
        break;
      case 'MEDIDA':
        icon = Icons.straighten_outlined;
        color = EagleTokens.purple;
        kind = 'Medida';
        break;
      case 'AUTONOMIA':
        icon = Icons.touch_app_outlined;
        color = EagleTokens.warn;
        kind = 'Autonomia';
        break;
      case 'FINANCEIRO':
        icon = Icons.payments_outlined;
        color = EagleTokens.bad;
        kind = 'Financeiro';
        break;
      default:
        if (tipo.startsWith('CHAT_')) {
          icon = Icons.chat_bubble_outline;
          color = primary;
          kind = 'Chat';
        } else {
          icon = Icons.bolt_outlined;
          color = TokensStrip.textSecondary;
          kind = tipo;
        }
    }
    final deep = e.deepLink.trim().isEmpty ? null : e.deepLink.trim();
    final rawBody = e.corpo.isEmpty ? e.meta : e.corpo;
    return Timeline360Item(
      at: at,
      kind: kind,
      title: sanitizeTimeline360Copy(e.titulo),
      body: sanitizeTimeline360Copy(rawBody),
      meta: sanitizeTimeline360Copy(e.meta),
      priority: e.prioridade.trim().isEmpty ? 'P2' : e.prioridade.trim(),
      icon: icon,
      color: color,
      deepLink: deep,
    );
  }

  List<Timeline360Item> _allItems(Color primary) {
    if (!timelineApiAsync.hasValue) {
      return const [];
    }
    final mapped =
        timelineApiAsync.value!
            .map((event) => itemFromApi(event, primary: primary))
            .toList();
    final filtered =
        mapped
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

  void _openTimelineCheckin(BuildContext context) {
    showAlunoCheckinMessageSheet(
      context,
      alunoId: aluno.id,
      alunoNome: aluno.nome,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final mute = fxScreenMute(context);
    final loading =
        timelineApiAsync.isLoading &&
        (!timelineApiAsync.hasValue || timelineApiAsync.isRefreshing);
    final refreshing =
        timelineApiAsync.isRefreshing && timelineApiAsync.hasValue;
    final error = timelineApiAsync.hasError && !timelineApiAsync.hasValue;
    final allItems = _allItems(primary);
    final visibleItems = allItems.take(3).toList();
    final hasMore = allItems.length > visibleItems.length;

    return Semantics(
      container: true,
      label: 'Linha do tempo 360, últimos sinais do aluno',
      child: Container(
      padding: const EdgeInsets.all(Aluno360Layout.cardPadding),
      decoration: Aluno360Layout.operacaoInsetSectionDecoration(
        context,
        primary: primary,
        isDark: isDark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Aluno360SectionHeader(
            icon: Icons.timeline_rounded,
            title: 'Linha do tempo 360',
            subtitle: 'Últimos sinais consolidados do aluno.',
            isDark: isDark,
          ),
          if (refreshing && !loading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: primary.withValues(alpha: 0.12),
                color: primary,
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (loading) ...[
            const SizedBox(height: 14),
            FxLoading.sectionShimmer(context, height: 140),
          ] else if (error) ...[
            const SizedBox(height: 14),
            Text(
              friendlyError(
                timelineApiAsync.error!,
                fallback: 'Não foi possível carregar a linha do tempo.',
              ),
              style: Aluno360Layout.cardSubtitleStyle(context).copyWith(
                color: mute,
                height: 1.35,
              ),
            ),
          ] else if (allItems.isEmpty) ...[
            const SizedBox(height: 14),
            Aluno360ActionEmptyPanel(
              key: const ValueKey('aluno360_timeline_empty'),
              icon: Icons.history_toggle_off_outlined,
              title: 'Linha do tempo ainda vazia',
              subtitle:
                  compactEmpty
                      ? 'Quando houver check-in ou chat, os sinais aparecem aqui em ordem cronológica.'
                      : '${aluno.nome.split(' ').first} ainda não tem sinais suficientes. '
                          'Peça um check-in ou abra o chat para registrar a próxima interação.',
              showPrimary: !compactEmpty,
              primaryLabel: compactEmpty ? null : 'Pedir check-in',
              primaryIcon: compactEmpty ? null : Icons.message_outlined,
              onPrimary:
                  compactEmpty ? null : () => _openTimelineCheckin(context),
              secondaryActions:
                  compactEmpty
                      ? [
                        Aluno360SecondaryAction(
                          label: 'Abrir chat',
                          icon: Icons.chat_bubble_outline,
                          onTap:
                              () => context.push(
                                '/alunos/${aluno.id}/chat',
                                extra: aluno.nome,
                              ),
                        ),
                      ]
                      : [
                        Aluno360SecondaryAction(
                          label: 'Abrir chat',
                          icon: Icons.chat_bubble_outline,
                          onTap:
                              () => context.push(
                                '/alunos/${aluno.id}/chat',
                                extra: aluno.nome,
                              ),
                        ),
                        Aluno360SecondaryAction(
                          label: 'Ver treinos',
                          icon: Icons.fitness_center_rounded,
                          onTap:
                              () => context.push(
                                '/alunos/${aluno.id}/treinos-list',
                                extra: aluno.nome,
                              ),
                        ),
                      ],
            ),
          ] else ...[
            const SizedBox(height: 14),
            for (var i = 0; i < visibleItems.length; i++) ...[
              Aluno360TimelineTileEntrance(
                index: i,
                child: Timeline360Tile(
                  item: visibleItems[i],
                  isDark: isDark,
                  accent: primary,
                  alunoFirstName: aluno.nome.split(' ').first,
                  showSpineBelow: i < visibleItems.length - 1,
                ),
              ),
              if (i < visibleItems.length - 1) const SizedBox(height: 10),
            ],
            if (hasMore) ...[
              const SizedBox(height: 6),
              Semantics(
                button: true,
                label: 'Ver todos os ${allItems.length} sinais da linha do tempo',
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showFullTimeline(context, primary),
                    style: Aluno360Layout.operacaoOutlinedButtonStyle(
                      context,
                      primary,
                    ),
                    child: Text('Ver todos os ${allItems.length} sinais'),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    ),
    );
  }

  void _showFullTimeline(BuildContext context, Color primary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => Aluno360TimelineFullSheet(
            aluno: aluno,
            isDark: isDark,
            primary: primary,
          ),
    );
  }
}

typedef Timeline360ExpandableTap = void Function(
  BuildContext tileContext,
  Timeline360Item item,
);

class Timeline360Item {
  const Timeline360Item({
    required this.at,
    required this.kind,
    required this.title,
    required this.body,
    required this.meta,
    required this.priority,
    required this.icon,
    required this.color,
    this.deepLink,
  });

  final DateTime? at;
  final String kind;
  final String title;
  final String body;
  final String meta;
  final String priority;
  final IconData icon;
  final Color color;
  final String? deepLink;
}

void showTimeline360BodySheet(
  BuildContext context,
  Timeline360Item item, {
  required Color accent,
  required bool isDark,
}) {
  final ink = fxScreenInk(context);
  final mute = fxScreenMute(context);
  final link = item.deepLink;
  final title = timeline360SheetTitle(
    kind: item.kind,
    title: item.title,
    meta: item.meta,
  );
  final linkColor = Aluno360Layout.timelineLinkForeground(
    accent,
    isDark: isDark,
  );
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder:
        (ctx) => Aluno360TimelineSheetEntrance(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12 + MediaQuery.paddingOf(ctx).top,
              16,
              16 + MediaQuery.paddingOf(ctx).bottom,
            ),
            child: ShellSurface(
              radius: 24,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.72,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: Aluno360Layout.sectionTitleStyle(
                                  context,
                                  ink,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Fechar',
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: Icon(Icons.close_rounded, color: mute),
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatTimeline360Date(item.at),
                        style: Aluno360Layout.timelineMetaStyle(context),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.body,
                        style: Aluno360Layout.captionStyle(context).copyWith(
                          color: ink,
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (link != null && link.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              ctx.push(link);
                            },
                            icon: Icon(
                              item.kind == 'Chat'
                                  ? Icons.chat_bubble_outline
                                  : Icons.open_in_new_rounded,
                              size: 18,
                            ),
                            label: Text(
                              item.kind == 'Chat'
                                  ? 'Abrir chat'
                                  : 'Abrir destino',
                            ),
                            style: Aluno360Layout.operacaoOutlinedButtonStyle(
                              context,
                              accent,
                            ).copyWith(
                              foregroundColor: WidgetStatePropertyAll(
                                linkColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
  );
}

class Timeline360Tile extends StatelessWidget {
  const Timeline360Tile({
    super.key,
    required this.item,
    required this.isDark,
    required this.accent,
    this.alunoFirstName,
    this.onExpandableTap,
    this.showSpineBelow = false,
    this.inkWell = true,
  });

  final Timeline360Item item;
  final bool isDark;
  final Color accent;
  final String? alunoFirstName;
  final Timeline360ExpandableTap? onExpandableTap;
  final bool showSpineBelow;
  final bool inkWell;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final link = item.deepLink;
    final previewBody =
        item.kind == 'Chat'
            ? timeline360ChatPreviewBody(
              item.body,
              alunoFirstName: alunoFirstName,
            )
            : item.kind == 'Autonomia'
                ? timeline360LocalizeAutonomiaActionCode(item.body)
                : item.body;
    final expandable = timeline360BodyExpandable(
      item.body,
      kind: item.kind,
      previewBody: previewBody,
    );
    final showMeta = timeline360ShouldShowMetaChip(
      kind: item.kind,
      meta: item.meta,
      priority: item.priority,
      title: item.title,
    );
    final showPriority = timeline360ShouldShowPriorityBadge(kind: item.kind);
    final kindHeader = timeline360KindHeader(
      kind: item.kind,
      title: item.title,
      meta: item.meta,
    );
    final showTitle = timeline360ShowTitleRow(
      kind: item.kind,
      title: item.title,
      meta: item.meta,
    );
    final hasFooterChips = timeline360HasFooterChips(
      kind: item.kind,
      meta: item.meta,
      priority: item.priority,
      title: item.title,
    );
    final linkColor = Aluno360Layout.timelineLinkForeground(
      accent,
      isDark: isDark,
    );
    final expandLabel = timeline360ExpandLinkLabel(kind: item.kind);
    final spineColor = ShellChrome.of(context).line.withValues(alpha: 0.55);
    final iconSize = Aluno360Layout.timelineTileIconSize;
    final child = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: iconSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (showSpineBelow)
                Positioned(
                  top: iconSize - 2,
                  left: iconSize / 2 - Aluno360Layout.timelineSpineWidth / 2,
                  bottom: -12,
                  width: Aluno360Layout.timelineSpineWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: spineColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(
                    Aluno360Layout.timelineTileIconRadius,
                  ),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: Aluno360Layout.timelineTileIconGlyphSize,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    kindHeader,
                    style: Aluno360Layout.timelineTileTitleStyle(
                      context,
                      item.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formatTimeline360Date(item.at),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Aluno360Layout.timelineMetaStyle(context),
                    ),
                  ),
                ],
              ),
              if (showTitle) ...[
                const SizedBox(height: 3),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Aluno360Layout.timelineTileTitleStyle(context, ink),
                ),
              ],
              const SizedBox(height: 3),
              Text(
                previewBody,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Aluno360Layout.captionStyle(context).copyWith(
                  color: mute,
                  height: 1.35,
                ),
              ),
              if (expandable) ...[
                const SizedBox(height: 4),
                Text(
                  expandLabel,
                  style: Aluno360Layout.chipLabelStyle(
                    context,
                    color: linkColor,
                  ).copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: linkColor.withValues(alpha: 0.55),
                  ),
                ),
              ],
              if (hasFooterChips) ...[
                SizedBox(height: expandable ? 10 : 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (showPriority)
                      Aluno360TimelinePriorityBadge(
                        priority: item.priority,
                        accent: accent,
                        isDark: isDark,
                      ),
                    if (showMeta)
                      Aluno360MiniAutonomyChip(
                        label: item.meta,
                        color: item.color,
                        isDark: isDark,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final semanticsLabel =
        '${item.kind}: $kindHeader. ${formatTimeline360Date(item.at)}. $previewBody';

    void onTap() {
      if (expandable) {
        if (onExpandableTap != null) {
          onExpandableTap!(context, item);
        } else {
          showTimeline360BodySheet(
            context,
            item,
            accent: accent,
            isDark: isDark,
          );
        }
        return;
      }
      if (link != null && link.isNotEmpty) {
        context.push(link);
      }
    }

    final tappable = expandable || (link != null && link.isNotEmpty);
    if (!tappable) {
      return Semantics(label: semanticsLabel, child: child);
    }
    final padded = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: child,
    );
    if (!inkWell) {
      return Semantics(
        button: true,
        label:
            expandable
                ? '$semanticsLabel. Toque para $expandLabel'
                : semanticsLabel,
        child: GestureDetector(onTap: onTap, child: padded),
      );
    }
    return Semantics(
      button: true,
      label:
          expandable
              ? '$semanticsLabel. Toque para $expandLabel'
              : semanticsLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: padded,
      ),
    );
  }
}
