import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
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
import 'aluno360_timeline_priority_badge.dart';
import 'aluno360_timeline_sheet_motion.dart';
import 'aluno_outreach_message_sheet.dart';

class Aluno360TimelineCard extends StatelessWidget {
  const Aluno360TimelineCard({
    super.key,
    required this.aluno,
    required this.timelineApiAsync,
    required this.isDark,
  });

  final Aluno aluno;
  final AsyncValue<List<Timeline360Event>> timelineApiAsync;
  final bool isDark;

  static Timeline360Item _itemFromApi(
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

  List<Timeline360Item> _items(Color primary) {
    if (!timelineApiAsync.hasValue) {
      return const [];
    }
    return timelineApiAsync.value!
        .take(7)
        .map((event) => _itemFromApi(event, primary: primary))
        .toList();
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
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final line = ShellChrome.of(context).line;
    final loading = timelineApiAsync.isLoading && !timelineApiAsync.hasValue;
    final error = timelineApiAsync.hasError && !timelineApiAsync.hasValue;
    final items = _items(primary);
    final visibleItems = items.take(3).toList();
    final hasMore = items.length > visibleItems.length;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: isDark),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.timeline_rounded, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Linha do tempo 360',
                      style: Aluno360Layout.cardTitleStyle(context, ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Últimos sinais consolidados do aluno.',
                      style: Aluno360Layout.cardSubtitleStyle(context).copyWith(
                        color: mute,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          ] else if (items.isEmpty) ...[
            const SizedBox(height: 14),
            Aluno360ActionEmptyPanel(
              key: const ValueKey('aluno360_timeline_empty'),
              icon: Icons.timeline_rounded,
              title: 'Linha do tempo ainda vazia',
              subtitle:
                  '${aluno.nome.split(' ').first} ainda não tem sinais suficientes. Peça um check-in ou abra o chat para registrar a próxima interação.',
              primaryLabel: 'Pedir check-in',
              primaryIcon: Icons.message_outlined,
              onPrimary: () => _openTimelineCheckin(context),
              secondaryActions: [
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
            for (final item in visibleItems) ...[
              Timeline360Tile(
                item: item,
                isDark: isDark,
                accent: primary,
              ),
              if (item != visibleItems.last) Divider(height: 18, color: line),
            ],
            if (hasMore) ...[
              const SizedBox(height: 6),
              Semantics(
                button: true,
                label: 'Ver histórico completo da linha do tempo',
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showFullTimeline(context, items, primary),
                    child: Text('Ver histórico completo · ${items.length}'),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showFullTimeline(
    BuildContext context,
    List<Timeline360Item> items,
    Color primary,
  ) {
    final chrome = ShellChrome.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.78,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder:
                (context, controller) => Aluno360TimelineSheetEntrance(
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
                    child: ListView.separated(
                      controller: controller,
                      itemCount: items.length + 1,
                      separatorBuilder: (_, index) {
                        if (index == 0) return const SizedBox(height: 12);
                        return Divider(
                          height: 18,
                          color: chrome.line,
                        );
                      },
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final ink = fxScreenInk(context);
                          final mute = fxScreenMute(context);
                          return Semantics(
                            header: true,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Histórico 360',
                                    style: Aluno360Layout.sectionTitleStyle(
                                      context,
                                      ink,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Fechar histórico',
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  icon: Icon(Icons.close_rounded, color: mute),
                                ),
                              ],
                            ),
                          );
                        }
                        return Timeline360Tile(
                          item: items[index - 1],
                          isDark: isDark,
                          accent: primary,
                        );
                      },
                    ),
                  ),
                ),
                ),
          ),
    );
  }
}

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

void showTimeline360BodySheet(BuildContext context, Timeline360Item item) {
  final ink = fxScreenInk(context);
  final mute = fxScreenMute(context);
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
            12,
            16,
            16 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: ShellSurface(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.kind} · ${item.title}',
                        style: TextStyle(
                          color: ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(Icons.close_rounded, color: mute),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.body,
                  style: Aluno360Layout.captionStyle(context).copyWith(
                    color: ink,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
  });

  final Timeline360Item item;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final link = item.deepLink;
    final expandable = timeline360BodyExpandable(item.body);
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
    final child = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: isDark ? 0.16 : 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: item.color, size: 17),
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
                    style: Aluno360Layout.chipLabelStyle(
                      context,
                      color: item.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formatTimeline360Date(item.at),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Aluno360Layout.captionStyle(context).copyWith(
                        color: mute,
                        fontWeight: FontWeight.w600,
                      ),
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
                item.body,
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
                  'Ver mensagem completa',
                  style: Aluno360Layout.captionStyle(context).copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                    decorationColor: accent.withValues(alpha: 0.45),
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
                      Aluno360MiniAutonomyChip(label: item.meta, color: mute),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final semanticsLabel =
        '${item.kind}: ${item.title}. ${formatTimeline360Date(item.at)}';

    void onTap() {
      if (expandable) {
        showTimeline360BodySheet(context, item);
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
    return Semantics(
      button: true,
      label:
          expandable
              ? '$semanticsLabel. Toque para ver mensagem completa'
              : semanticsLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: child,
        ),
      ),
    );
  }
}

String formatTimeline360Date(DateTime? value) {
  if (value == null) return 'sem data';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month às $hour:$minute';
}
