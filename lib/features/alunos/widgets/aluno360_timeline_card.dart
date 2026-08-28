import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_timeline_logic.dart';
import 'aluno360_action_empty_panel.dart';
import 'aluno360_help_sheets.dart';
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

  void _openTimelineCheckin(BuildContext context) {
    showAlunoCheckinMessageSheet(
      context,
      alunoId: aluno.id,
      alunoNome: aluno.nome,
    );
  }

  void _onTimelineItemTap(BuildContext context, Timeline360Item item) {
    final link = item.deepLink;
    final previewBody =
        item.kind == 'Chat'
            ? timeline360ChatPreviewBody(
              item.body,
              alunoFirstName: aluno.nome.split(' ').first,
            )
            : item.kind == 'Autonomia'
            ? timeline360LocalizeAutonomiaActionCode(item.body)
            : item.body;
    final expandable = timeline360BodyExpandable(
      item.body,
      kind: item.kind,
      previewBody: previewBody,
    );
    if (expandable) {
      showTimeline360BodySheet(
        context,
        item,
        accent: Theme.of(context).colorScheme.primary,
        isDark: isDark,
      );
      return;
    }
    if (link != null && link.isNotEmpty) {
      context.push(link);
    }
  }

  String _timelineTileLabel(Timeline360Item item) {
    final kindHeader = timeline360KindHeader(
      kind: item.kind,
      title: item.title,
      meta: item.meta,
    );
    if (timeline360ShowTitleRow(
      kind: item.kind,
      title: item.title,
      meta: item.meta,
    )) {
      return item.title;
    }
    return kindHeader;
  }

  String? _timelineTileSubtitle(Timeline360Item item) {
    final previewBody =
        item.kind == 'Chat'
            ? timeline360ChatPreviewBody(
              item.body,
              alunoFirstName: aluno.nome.split(' ').first,
            )
            : item.kind == 'Autonomia'
            ? timeline360LocalizeAutonomiaActionCode(item.body)
            : item.body;
    final showMeta = timeline360ShouldShowMetaChip(
      kind: item.kind,
      meta: item.meta,
      priority: item.priority,
      title: item.title,
    );
    final showPriority = timeline360ShouldShowPriorityBadge(kind: item.kind);
    final parts = <String>[previewBody];
    if (showPriority) parts.add(item.priority);
    if (showMeta && item.meta.isNotEmpty) parts.add(item.meta);
    return parts.join(' · ');
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
      child: FxSettingsGroup(
        header: 'Linha do tempo 360',
        helpTooltip: 'Ajuda sobre a linha do tempo',
        onHelpTap: () => showAluno360TimelineHelpSheet(context),
        accent: primary,
        children: [
          if (refreshing && !loading) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  color: primary,
                ),
              ),
            ),
          ],
          if (loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FxLoading.sectionShimmer(context, height: 140),
            )
          else if (error)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                friendlyError(
                  timelineApiAsync.error!,
                  fallback: 'Não foi possível carregar a linha do tempo.',
                ),
                style: Aluno360Layout.cardSubtitleStyle(
                  context,
                ).copyWith(color: mute, height: 1.35),
              ),
            )
          else if (allItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Aluno360ActionEmptyPanel(
                key: const ValueKey('aluno360_timeline_empty'),
                compact: true,
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
            )
          else
            for (var i = 0; i < visibleItems.length; i++)
              Aluno360TimelineTileEntrance(
                index: i,
                child: FxSettingsTile(
                  icon: visibleItems[i].icon,
                  accent: visibleItems[i].color,
                  label: _timelineTileLabel(visibleItems[i]),
                  subtitle: _timelineTileSubtitle(visibleItems[i]),
                  value: formatTimeline360Date(visibleItems[i].at),
                  onTap: () => _onTimelineItemTap(context, visibleItems[i]),
                  showDivider: i < visibleItems.length - 1 || hasMore,
                ),
              ),
          if (!loading && !error && allItems.isNotEmpty && hasMore)
            FxSettingsTile(
              icon: Icons.unfold_more_rounded,
              label: 'Ver todos os ${allItems.length} sinais',
              subtitle: 'Linha do tempo completa',
              value: '',
              showDivider: false,
              onTap: () => _showFullTimeline(context, primary),
            ),
        ],
      ),
    );
  }

  void _showFullTimeline(BuildContext context, Color primary) {
    showFxHomeSheet<void>(
      context,
      builder:
          (ctx) => Aluno360TimelineFullSheet(
            aluno: aluno,
            isDark: isDark,
            primary: primary,
          ),
    );
  }
}

typedef Timeline360ExpandableTap =
    void Function(BuildContext tileContext, Timeline360Item item);

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
  showFxHomeSheet<void>(
    context,
    builder: (ctx) {
      final maxHeight =
          MediaQuery.sizeOf(ctx).height * FxHomeSheetChrome.maxHeightFactor;
      return FxHomeSheetSurface(
        isDark: isDark,
        maxHeight: maxHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxHomeSheetHandle(isDark: isDark),
            SizedBox(height: TokensStrip.s4),
            FxHomeSheetHeader(
              isDark: isDark,
              title: title,
              subtitle: formatTimeline360Date(item.at),
              leading: Icon(item.icon, color: item.color, size: 18),
            ),
            SizedBox(height: TokensStrip.s3),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            foregroundColor: WidgetStatePropertyAll(linkColor),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Mantido para a sheet completa e testes de contrato da timeline.
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
    final kindHeader = timeline360KindHeader(
      kind: item.kind,
      title: item.title,
      meta: item.meta,
    );
    final label =
        timeline360ShowTitleRow(
          kind: item.kind,
          title: item.title,
          meta: item.meta,
        )
            ? item.title
            : kindHeader;

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
      final link = item.deepLink;
      if (link != null && link.isNotEmpty) {
        context.push(link);
      }
    }

    return FxSettingsTile(
      icon: item.icon,
      accent: item.color,
      label: label,
      subtitle: previewBody,
      value: formatTimeline360Date(item.at),
      onTap: onTap,
      showDivider: showSpineBelow,
    );
  }
}
