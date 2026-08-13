import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../chat/screens/chat_inbox_screen.dart';
import '../data/command_action_item.dart';
import '../providers/dashboard_provider.dart';
import '../utils/dashboard_chat_subtitle.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_next_actions.dart';
import '../utils/dashboard_readability.dart';
import '../utils/dashboard_unread.dart';
import 'command_action_panel.dart';
import 'command_priorities_sheet.dart';

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
    required this.nextActions,
    required this.prioritiesSheetActions,
    required this.showPrioritiesLink,
    this.panelKey,
    this.mensagensNaoLidas,
    this.contextualSubtitle,
    this.hideHeader = false,
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
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primary = widget.primary;
    final nextActions = widget.nextActions;
    final prioritiesSheetActions = widget.prioritiesSheetActions;
    final showPrioritiesLink = widget.showPrioritiesLink;
    final contextualSubtitle = widget.contextualSubtitle;
    final mute = dashboardReadableCaption(context, isDark: isDark);
    final heading = BrandPalette.sectionHeading(primary, dark: isDark);

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
        const SizedBox(height: 10),
        _MessagesShortcutRow(
          isDark: isDark,
          primary: primary,
          title: 'Mensagens',
          subtitle: chatSubtitle,
          onTap: () => context.go('/chat/inbox'),
        ),
      ],
    );
  }
}

class _MessagesShortcutRow extends StatelessWidget {
  const _MessagesShortcutRow({
    required this.isDark,
    required this.primary,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool isDark;
  final Color primary;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final actionColor = BrandPalette.sectionAction(primary, dark: isDark);
    final kicker = dashboardMicroLabelStyle(
      context,
      isDark: isDark,
      color: actionColor,
      fontWeight: FontWeight.w700,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DashboardMicrocopy.atalhoKicker, style: kicker),
        const SizedBox(height: 4),
        Semantics(
          button: true,
          label: '$title. $subtitle',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(TokensStrip.rInput),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Row(
                children: [
                  FxIcon(
                    name: 'message-circle',
                    size: 18,
                    color: actionColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: title,
                            style: dashboardCardTitleStyle(ink).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: ' · $subtitle',
                            style: dashboardCardSubtitleStyle(
                              context,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  FxIcon(name: 'chevron-right', color: actionColor, size: 16),
                ],
              ),
            ),
          ),
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
