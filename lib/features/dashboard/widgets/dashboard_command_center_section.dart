import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../chat/screens/chat_inbox_screen.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../data/command_action_item.dart';
import '../providers/dashboard_provider.dart';
import '../utils/dashboard_chat_subtitle.dart';
import '../utils/dashboard_entry_motion.dart';
import '../utils/dashboard_haptic.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_next_actions.dart';
import '../utils/dashboard_readability.dart';
import '../utils/dashboard_unread.dart';
import 'command_action_panel.dart';
import 'command_priorities_sheet.dart';
import 'dashboard_horizontal_scroll_peek.dart';

export '../data/command_action_item.dart';
export '../utils/dashboard_next_actions.dart'
    show
        buildDashboardNextActions,
        buildDashboardSheetActions,
        dashboardShouldShowPrioritiesLink,
        DashboardRiskStudentRef;
export 'command_action_panel.dart';
export 'command_action_tile.dart';
export 'command_priorities_sheet.dart';
export 'command_status_tile.dart';

class DashboardCommandCenterSection extends ConsumerStatefulWidget {
  final bool isDark;
  final Color primary;
  final FinanceiroDashboard? finData;

  /// Fila curada e prioridades — computadas UMA vez pelo pai
  /// (`personal_dashboard_screen_build.part.dart`) e só renderizadas aqui.
  /// Esta seção é puramente apresentacional para essas listas.
  final List<CommandActionItem> nextActions;
  final List<CommandActionItem> prioritiesSheetActions;
  final bool showPrioritiesLink;

  /// Key da região do painel — usada pelo pai para medir quando ele sai da
  /// viewport e decidir o CTA sticky.
  final GlobalKey? panelKey;

  /// Não-lidas do BFF `pulse` (preferidas ao inbox se informadas).
  final int? mensagensNaoLidas;

  final String? contextualSubtitle;
  final bool hideHeader;
  final bool collapseQuickLinks;

  /// Props da agregação do pai — evitam re-watch de inbox/alunos/command.
  final int? alunosAtivos;
  final int? agendaHojeCount;
  final int? unreadCount;
  final int? conversationCount;
  final bool? isCommandPreparing;
  final bool? commandUnavailable;

  const DashboardCommandCenterSection({
    super.key,
    required this.isDark,
    required this.primary,
    required this.finData,
    required this.nextActions,
    required this.prioritiesSheetActions,
    required this.showPrioritiesLink,
    this.panelKey,
    this.mensagensNaoLidas,
    this.contextualSubtitle,
    this.hideHeader = false,
    this.collapseQuickLinks = true,
    this.alunosAtivos,
    this.agendaHojeCount,
    this.unreadCount,
    this.conversationCount,
    this.isCommandPreparing,
    this.commandUnavailable,
  });

  @override
  ConsumerState<DashboardCommandCenterSection> createState() =>
      DashboardCommandCenterSectionState();
}

class DashboardCommandCenterSectionState
    extends ConsumerState<DashboardCommandCenterSection> {
  late bool _quickLinksExpanded;

  @override
  void initState() {
    super.initState();
    _quickLinksExpanded = !widget.collapseQuickLinks;
  }

  @override
  void didUpdateWidget(covariant DashboardCommandCenterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.collapseQuickLinks && !oldWidget.collapseQuickLinks) {
      _quickLinksExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primary = widget.primary;
    final finData = widget.finData;
    final nextActions = widget.nextActions;
    final prioritiesSheetActions = widget.prioritiesSheetActions;
    final showPrioritiesLink = widget.showPrioritiesLink;
    final contextualSubtitle = widget.contextualSubtitle;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dashboardReadableCaption(context, isDark: isDark);
    final heading = BrandPalette.sectionHeading(primary, dark: isDark);
    final actionColor = BrandPalette.sectionAction(primary, dark: isDark);
    final rowAccent = BrandPalette.sectionAccent(primary, dark: isDark);

    // Prefer props do pai (snapshot). Fallback a watches só se omitidos.
    final useParentPulse = widget.alunosAtivos != null;
    final chatAsync = useParentPulse ? null : ref.watch(chatInboxProvider);
    final commandAsync =
        useParentPulse ? null : ref.watch(commandCenterProvider);
    final isCommandPreparing =
        widget.isCommandPreparing ?? commandAsync?.isLoading ?? false;
    final commandUnavailable =
        widget.commandUnavailable ?? commandAsync?.hasError ?? false;
    final unreadFromInbox =
        chatAsync?.maybeWhen(
          data: (items) => items.fold<int>(0, (sum, i) => sum + i.naoLidas),
          orElse: () => 0,
        ) ??
        0;
    final unreadCount =
        widget.unreadCount ??
        dashboardResolveUnreadCount(
          pulseUnread: widget.mensagensNaoLidas,
          inboxReady: chatAsync?.hasValue ?? false,
          inboxUnread: unreadFromInbox,
        );
    final totalConversas =
        widget.conversationCount ??
        chatAsync?.maybeWhen(data: (items) => items.length, orElse: () => 0) ??
        0;
    final chatSubtitle = dashboardChatShortcutSubtitle(
      unreadCount: unreadCount,
      conversationCount: totalConversas,
    );

    Widget card({
      required double width,
      required String icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Semantics(
            button: true,
            label: '$title. $subtitle',
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: fxStripCardDecoration(
                  context,
                  accent: primary,
                  radius: TokensStrip.rCard,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: primarySoft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: FxIcon(name: icon, size: 17, color: rowAccent),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: dashboardCardTitleStyle(
                              ink,
                            ).copyWith(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: dashboardCardSubtitleStyle(
                              context,
                              isDark: isDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.hideHeader) ...[
          Text(
            DashboardMicrocopy.commandCenterTitle,
            style: dashboardSectionTitleStyle(
              context,
              color: heading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            contextualSubtitle ??
                'A melhor próxima ação para proteger receita e aderência.',
            style: TokensStrip.bodyMuted(color: mute).copyWith(
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
        ],
        CommandActionPanel(
          key: widget.panelKey,
          isDark: isDark,
          primary: primary,
          loading: isCommandPreparing,
          unavailable: commandUnavailable,
          actions: nextActions,
          prioritiesActionLabel:
              showPrioritiesLink ? DashboardMicrocopy.maisPrioridades : null,
          onPrioritiesTap:
              showPrioritiesLink
                  ? () => showCommandActionsSheet(
                    context,
                    isDark: isDark,
                    primary: primary,
                    actions: prioritiesSheetActions,
                  )
                  : null,
        ),
        const SizedBox(height: 14),
        Material(
          color: Colors.transparent,
          child: Semantics(
            button: true,
            expanded: _quickLinksExpanded,
            label:
                _quickLinksExpanded
                    ? 'Atalhos rápidos, expandido. Toque para recolher'
                    : 'Atalhos rápidos, recolhido. Mensagens. Toque para expandir',
            child: InkWell(
              onTap: () {
                dashboardHapticCollapseToggle();
                setState(() => _quickLinksExpanded = !_quickLinksExpanded);
              },
              borderRadius: BorderRadius.circular(TokensStrip.rInput),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(
                      'Atalhos rápidos',
                      style: FocuxHubTypography.eyebrow(
                        context,
                        color: heading,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '1',
                        style: dashboardChipLabelStyle(actionColor),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _quickLinksExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 16,
                      color: actionColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final moduleWidth = (constraints.maxWidth * 0.46).clamp(
                  150.0,
                  188.0,
                );
                return DashboardHorizontalScrollPeek(
                  showPeek: true,
                  child: SizedBox(
                    height: 82,
                    child: ListView(
                      key: const PageStorageKey('personal-command-modules'),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        card(
                          width: moduleWidth,
                          icon: 'message-circle',
                          title: 'Mensagens',
                          subtitle: chatSubtitle,
                          onTap: () => context.go('/chat/inbox'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          crossFadeState:
              _quickLinksExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
          duration: dashboardMotionDuration(context),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

void showCommandActionsSheet(
  BuildContext context, {
  required bool isDark,
  required Color primary,
  required List<CommandActionItem> actions,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.56 : 0.24),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return CommandPrioritiesSheet(
        parentContext: context,
        sheetContext: sheetContext,
        isDark: isDark,
        primary: primary,
        actions: actions,
      );
    },
  );
}
