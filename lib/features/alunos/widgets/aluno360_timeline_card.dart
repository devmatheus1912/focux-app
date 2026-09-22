import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_timeline_logic.dart';
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
        alunoId: aluno.id,
      );
      return;
    }
    final link = resolveTimeline360DeepLinkForPersonal(
      link: item.deepLink,
      alunoId: aluno.id,
    );
    if (link.isNotEmpty) {
      context.push(link);
    }
  }

  String _timelineTileLabel(Timeline360Item item) {
    return timeline360ListLabel(
      kind: item.kind,
      title: item.title,
      meta: item.meta,
    );
  }

  String _timelineTileSubtitle(Timeline360Item item) {
    return timeline360ListSubtitle(
      kind: item.kind,
      title: item.title,
      body: item.body,
      alunoFirstName: aluno.nome.split(' ').first,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: 'Linha do tempo 360',
            actionLabel: 'Ajuda',
            onAction: () => showAluno360TimelineHelpSheet(context),
          ),
          if (allItems.isEmpty && !loading && !error) ...[
            const SizedBox(height: 4),
            Text(
              compactEmpty
                  ? 'Quando houver check-in ou chat, os sinais aparecem aqui em ordem cronológica.'
                  : '${aluno.nome.split(' ').first} ainda não tem sinais suficientes. '
                      'Peça um check-in ou abra o chat para registrar a próxima interação.',
              style: Aluno360Layout.metaStyle(context).copyWith(color: mute),
            ),
          ],
          const SizedBox(height: TokensStrip.s3),
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
            KeyedSubtree(
              key: const ValueKey('aluno360_timeline_empty'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: TokensStrip.s2,
                    runSpacing: TokensStrip.s2,
                    children: [
                      if (!compactEmpty)
                        DashboardHomeActionChip(
                          label: 'Pedir check-in',
                          accent: primary,
                          isDark: isDark,
                          onPressed: () => _openTimelineCheckin(context),
                        ),
                      DashboardHomeActionChip(
                        label: 'Abrir chat',
                        accent: primary,
                        isDark: isDark,
                        onPressed:
                            () => context.push(
                              '/alunos/${aluno.id}/chat',
                              extra: aluno.nome,
                            ),
                      ),
                      if (!compactEmpty)
                        DashboardHomeActionChip(
                          label: 'Ver treinos',
                          accent: primary,
                          isDark: isDark,
                          onPressed:
                              () => context.push(
                                '/alunos/${aluno.id}/treinos-list',
                                extra: aluno.nome,
                              ),
                        ),
                    ],
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < visibleItems.length; i++)
              Aluno360TimelineTileEntrance(
                index: i,
                child: FxSatelliteListTile(
                  title: _timelineTileLabel(visibleItems[i]),
                  titleCase: false,
                  isThreeLine: false,
                  subtitle: Text(
                    _timelineTileSubtitle(visibleItems[i]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  accent: visibleItems[i].color,
                  onTap: () => _onTimelineItemTap(context, visibleItems[i]),
                  trailing: Text(
                    formatTimeline360Date(visibleItems[i].at),
                    style: Aluno360Layout.metaStyle(context),
                  ),
                ),
              ),
          if (!loading && !error && allItems.isNotEmpty && hasMore)
            Align(
              alignment: Alignment.centerLeft,
              child: DashboardHomeActionChip(
                label: 'Ver todos os ${allItems.length} sinais',
                accent: primary,
                isDark: isDark,
                onPressed: () => _showFullTimeline(context, primary),
              ),
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
  int? alunoId,
}) {
  final ink = fxScreenInk(context);
  final link =
      alunoId == null
          ? (item.deepLink?.trim() ?? '')
          : resolveTimeline360DeepLinkForPersonal(
            link: item.deepLink,
            alunoId: alunoId,
          );
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
                    if (link.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final host = context;
                            Navigator.of(ctx).pop();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!host.mounted) return;
                              host.push(link);
                            });
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
    this.onRouteTap,
    this.showSpineBelow = false,
    this.inkWell = true,
  });

  final Timeline360Item item;
  final bool isDark;
  final Color accent;
  final String? alunoFirstName;
  final Timeline360ExpandableTap? onExpandableTap;
  /// Quando o tile está dentro de um sheet modal: fechar sheet antes do push.
  final Timeline360ExpandableTap? onRouteTap;
  final bool showSpineBelow;
  final bool inkWell;

  @override
  Widget build(BuildContext context) {
    final previewBody = timeline360ListSubtitle(
      kind: item.kind,
      title: item.title,
      body: item.body,
      alunoFirstName: alunoFirstName,
    );
    final expandable = timeline360BodyExpandable(
      item.body,
      kind: item.kind,
      previewBody: previewBody,
    );
    final label = timeline360ListLabel(
      kind: item.kind,
      title: item.title,
      meta: item.meta,
    );

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
      if (link == null || link.isEmpty) return;
      if (onRouteTap != null) {
        onRouteTap!(context, item);
        return;
      }
      context.push(link);
    }

    final hasRoute = item.deepLink != null && item.deepLink!.isNotEmpty;
    final interactive = expandable || hasRoute;
    final chrome = ShellChrome.of(context);
    final mute = chrome.mute;
    final ink = chrome.ink;
    final date = formatTimeline360Date(item.at);
    final spoken =
        expandable
            ? '$label. ${timeline360ExpandLinkLabel(kind: item.kind)}'
            : (previewBody.isEmpty ? label : '$label. $previewBody');

    return Semantics(
      button: interactive,
      label: date.isEmpty ? spoken : '$spoken. $date',
      hint: expandable ? 'Mostra o conteúdo completo' : null,
      child: InkWell(
        onTap:
            !interactive
                ? null
                : () {
                  HapticFeedback.selectionClick();
                  onTap();
                },
        child: DecoratedBox(
          decoration: BoxDecoration(
            border:
                showSpineBelow
                    ? Border(
                      bottom: BorderSide(
                        color: chrome.line,
                        width: 1,
                      ),
                    )
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TokensStrip.s3,
              vertical: TokensStrip.s3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, size: 20, color: item.color),
                const SizedBox(width: TokensStrip.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: Aluno360Layout.captionStyle(context).copyWith(
                          color: ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.25,
                        ),
                      ),
                      if (previewBody.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          previewBody,
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          style: Aluno360Layout.metaStyle(context).copyWith(
                            color: mute,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(width: TokensStrip.s2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 88),
                    child: Text(
                      date,
                      maxLines: 2,
                      softWrap: true,
                      textAlign: TextAlign.end,
                      style: Aluno360Layout.metaStyle(context).copyWith(
                        color: mute,
                      ),
                    ),
                  ),
                ],
                if (interactive) ...[
                  const SizedBox(width: TokensStrip.s1),
                  Icon(
                    expandable
                        ? Icons.expand_more
                        : Icons.chevron_right,
                    size: 18,
                    color: mute,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
