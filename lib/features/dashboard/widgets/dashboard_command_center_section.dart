import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../chat/screens/chat_inbox_screen.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../data/command_center_data.dart';
import '../providers/dashboard_provider.dart';
import '../utils/dashboard_entry_motion.dart';
import '../utils/dashboard_haptic.dart';
import '../utils/dashboard_command_copy.dart';
import '../utils/dashboard_screen_helpers.dart';
import 'dashboard_horizontal_scroll_peek.dart';

part 'dashboard_command_center_section_actions.part.dart';

class DashboardCommandCenterSection extends ConsumerStatefulWidget {
  final bool isDark;
  final Color primary;
  final FinanceiroDashboard? finData;
  final bool hideRiskSummary;
  final String? contextualSubtitle;
  final bool hideHeader;

  const DashboardCommandCenterSection({
    super.key,
    required this.isDark,
    required this.primary,
    required this.finData,
    this.hideRiskSummary = false,
    this.contextualSubtitle,
    this.hideHeader = false,
  });

  @override
  ConsumerState<DashboardCommandCenterSection> createState() =>
      DashboardCommandCenterSectionState();
}

class DashboardCommandCenterSectionState extends ConsumerState<DashboardCommandCenterSection> {
  bool _quickLinksExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primary = widget.primary;
    final finData = widget.finData;
    final hideRiskSummary = widget.hideRiskSummary;
    final contextualSubtitle = widget.contextualSubtitle;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final heading = BrandPalette.sectionHeading(primary, dark: isDark);
    final actionColor = BrandPalette.sectionAction(primary, dark: isDark);
    final rowAccent = BrandPalette.sectionAccent(primary, dark: isDark);

    // Chat inbox — count total unread messages
    final chatAsync = ref.watch(chatInboxProvider);
    final commandAsync = ref.watch(commandCenterProvider);
    final isCommandPreparing = commandAsync.isLoading;
    final commandUnavailable = commandAsync.hasError;
    final unreadCount = chatAsync.maybeWhen(
      data: (items) => items.fold<int>(0, (sum, i) => sum + i.naoLidas),
      orElse: () => 0,
    );
    final totalConversas = chatAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );
    final chatSubtitle =
        unreadCount > 0
            ? '$unreadCount não lida${unreadCount == 1 ? '' : 's'}'
            : '$totalConversas conversa${totalConversas == 1 ? '' : 's'}';

    // Alunos — active student count (already in parent but we watch again for isolation)
    final alunosAsync = ref.watch(alunosProvider);
    final alunosAtivos = alunosAsync.maybeWhen(
      data: (alunos) => alunos.where((a) => a.status == 'ATIVO').length,
      orElse: () => 0,
    );

    // Agenda today — count from agendaHojeProvider (commandCenterProvider)
    final agendaHoje = commandAsync.maybeWhen(
      data: (cc) => cc.agendaHoje.length,
      orElse: () => 0,
    );
    final agendaSubtitle = agendaHoje > 0 ? '$agendaHoje hoje' : 'Sem agenda';

    // Financeiro — monthly revenue from already-loaded _finData
    final receitaMes = finData?.receitaMes ?? 0;
    final finSubtitle =
        receitaMes > 0
            ? 'R\$ ${receitaMes.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}'
            : 'Ver finanças';

    final alunosRisco = commandAsync.maybeWhen(
      data: (cc) => cc.alunosEmRisco.length,
      orElse: () => 0,
    );
    final filaAcoes = commandAsync.maybeWhen(
      data: (cc) => cc.filaAcoes,
      orElse: () => const <FilaAcaoResumo>[],
    );
    final copilotAcoes =
        filaAcoes.where((a) => a.tipo == 'IA_COPILOTO').toList();
    final cobrancasPendentes = commandAsync.maybeWhen(
      data: (cc) => cc.cobrancasPendentes.length,
      orElse: () => finData?.totalInadimplentes ?? 0,
    );
    final nextActions = buildDashboardNextActions(
      filaAcoes: filaAcoes,
      unreadCount: unreadCount,
      alunosRisco: alunosRisco,
      cobrancasPendentes: cobrancasPendentes,
      agendaHoje: agendaHoje,
      hideRiskSummary: hideRiskSummary,
      isCommandPreparing: isCommandPreparing,
    );
    final prioritiesSheetActions = buildDashboardSheetActions(
      curated: nextActions,
      filaAcoes: filaAcoes,
    );
    final showPrioritiesLink =
        prioritiesSheetActions.length > 1 && !isCommandPreparing;

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
                          style: TextStyle(
                            fontSize: 12.8,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 11.2, color: mute),
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.hideHeader)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Central de Comando',
                      style: AppTypography.inter(
                        fontSize: TokensStrip.fontH2,
                        fontWeight: TokensStrip.weightH2,
                        letterSpacing: TokensStrip.trackingH2,
                        height: 1.2,
                        color: heading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contextualSubtitle ??
                          'A melhor próxima ação para proteger receita e aderência.',
                      style: AppTypography.inter(
                        fontSize: TokensStrip.fontBodySm,
                        fontWeight: FontWeight.w400,
                        height: TokensStrip.leadingBody,
                        color: mute,
                      ),
                    ),
                  ],
                ),
              ),
              if (showPrioritiesLink)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap:
                        () => showCommandActionsSheet(
                          context,
                          isDark: isDark,
                          primary: primary,
                          actions: prioritiesSheetActions,
                        ),
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isCommandPreparing
                                ? 'lendo sinais'
                                : 'Ver prioridades',
                            style: TextStyle(
                              color: actionColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (!isCommandPreparing) ...[
                            const SizedBox(width: 4),
                            FxIcon(
                              name: 'chevron-right',
                              size: 13,
                              color: actionColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        if (!widget.hideHeader) const SizedBox(height: 20),
        CommandActionPanel(
          isDark: isDark,
          primary: primary,
          loading: isCommandPreparing,
          unavailable: commandUnavailable,
          actions: nextActions.take(2).toList(growable: false),
          prioritiesActionLabel:
              showPrioritiesLink ? 'Ver prioridades' : null,
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
                    : 'Atalhos rápidos, recolhido. Copiloto, mensagens e mais. Toque para expandir',
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
                      style: AppTypography.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: heading,
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
                        '5',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: actionColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _quickLinksExpanded ? 0.25 : 0,
                      duration: dashboardMotionDuration(context),
                      curve: Curves.easeOutCubic,
                      child: FxIcon(
                        name: 'chevron-right',
                        size: 16,
                        color: actionColor,
                      ),
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
            final moduleWidth = (constraints.maxWidth * 0.46).clamp(150.0, 188.0);
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
                    icon: 'zap',
                    title: 'Copiloto',
                    subtitle:
                        copilotAcoes.isEmpty
                            ? 'Abrir Copiloto'
                            : '${copilotAcoes.length} aberta${copilotAcoes.length == 1 ? '' : 's'}',
                    onTap:
                        () => context.push('/dashboard/command-center/copiloto'),
                  ),
                  card(
                    width: moduleWidth,
                    icon: 'message-circle',
                    title: 'Mensagens',
                    subtitle: chatSubtitle,
                    onTap: () => context.go('/chat/inbox'),
                  ),
                  card(
                    width: moduleWidth,
                    icon: 'users',
                    title: 'Alunos',
                    subtitle: '$alunosAtivos ativos',
                    onTap: () => context.go('/alunos'),
                  ),
                  card(
                    width: moduleWidth,
                    icon: 'calendar',
                    title: 'Agenda',
                    subtitle: agendaSubtitle,
                    onTap: () => context.go('/agenda'),
                  ),
                  card(
                    width: moduleWidth,
                    icon: 'dollar-sign',
                    title: 'Financeiro',
                    subtitle: finSubtitle,
                    onTap: () => context.go('/financeiro'),
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
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

List<CommandActionItem> buildDashboardNextActions({
  required List<FilaAcaoResumo> filaAcoes,
  required int unreadCount,
  required int alunosRisco,
  required int cobrancasPendentes,
  required int agendaHoje,
  required bool hideRiskSummary,
  required bool isCommandPreparing,
}) {
  final copilotAcoes =
      filaAcoes.where((a) => a.tipo == 'IA_COPILOTO').toList();
  final filaNaoCopilot =
      filaAcoes.where((a) => a.tipo != 'IA_COPILOTO').toList();
  final queueAction =
      filaNaoCopilot.isEmpty
          ? null
          : (hideRiskSummary &&
                  isRiskEchoCopy(
                    '${filaNaoCopilot.first.titulo} ${filaNaoCopilot.first.descricao}',
                  )
              ? null
              : CommandActionItem(
                icon: 'zap',
                title: 'Executar próxima ação',
                subtitle: dashboardFormatActionCopy(
                  filaNaoCopilot.first.descricao,
                ),
                route:
                    filaNaoCopilot.first.acaoUrl.startsWith('/')
                        ? filaNaoCopilot.first.acaoUrl
                        : '/dashboard/personal',
                tone: CommandActionTone.primary,
              ));

  final nextActions = <CommandActionItem>[
    if (copilotAcoes.isNotEmpty)
      CommandActionItem(
        icon: 'zap',
        title: dashboardFormatActionCopy(
          copilotAcoes.first.titulo.isNotEmpty
              ? copilotAcoes.first.titulo
              : 'Revisar tarefa IA',
        ),
        subtitle: dashboardFormatActionCopy(copilotAcoes.first.descricao),
        route: '/dashboard/command-center/copiloto',
        tone: CommandActionTone.primary,
      ),
    if (unreadCount > 0)
      CommandActionItem(
        icon: 'message-circle',
        title: 'Responder mensagens',
        subtitle:
            '$unreadCount conversa${unreadCount == 1 ? '' : 's'} aguardando',
        route: '/chat/inbox',
        tone: CommandActionTone.hot,
      ),
    if (alunosRisco > 0 && !hideRiskSummary)
      CommandActionItem(
        icon: 'alert-triangle',
        title: 'Contato hoje',
        subtitle:
            '$alunosRisco no radar · risco, inadimplência ou pausa no treino',
        route: '/alunos?filtro=contato',
        tone: CommandActionTone.hot,
      ),
    if (cobrancasPendentes > 0)
      CommandActionItem(
        icon: 'dollar-sign',
        title: 'Cobrar pendências',
        subtitle:
            '$cobrancasPendentes mensalidade${cobrancasPendentes == 1 ? '' : 's'} no radar',
        route: '/financeiro',
        tone: CommandActionTone.money,
      ),
    if (queueAction != null) queueAction,
    if (agendaHoje > 0)
      CommandActionItem(
        icon: 'calendar',
        title: 'Preparar agenda',
        subtitle: '$agendaHoje compromisso${agendaHoje == 1 ? '' : 's'} hoje',
        route: '/agenda',
        tone: CommandActionTone.primary,
      ),
  ];

  if (nextActions.isEmpty && !isCommandPreparing) {
    nextActions.add(
      const CommandActionItem(
        icon: 'plus',
        title: 'Criar próxima oportunidade',
        subtitle: 'Cadastre aluno, treino ou lead antes do pico do dia',
        route: '/alunos/novo',
        tone: CommandActionTone.primary,
      ),
    );
  }

  return nextActions;
}

List<CommandActionItem> buildDashboardSheetActions({
  required List<CommandActionItem> curated,
  required List<FilaAcaoResumo> filaAcoes,
}) {
  final seenTitles = curated.map((a) => a.title).toSet();
  final extras = <CommandActionItem>[];
  for (final action in filaAcoes) {
    final title = dashboardFormatActionCopy(
      action.titulo.isNotEmpty ? action.titulo : 'Prioridade',
    );
    if (seenTitles.contains(title)) continue;
    seenTitles.add(title);
    extras.add(
      CommandActionItem(
        icon: 'zap',
        title: title,
        subtitle: dashboardFormatActionCopy(action.descricao),
        route:
            action.acaoUrl.startsWith('/')
                ? action.acaoUrl
                : '/dashboard/personal',
        tone: CommandActionTone.primary,
      ),
    );
  }
  return [...curated, ...extras].take(12).toList();
}

void showCommandActionsSheet(
  BuildContext context, {
  required bool isDark,
  required Color primary,
  required List<CommandActionItem> actions,
}) {
  final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
  final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.56 : 0.24),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      return Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          0,
          14,
          math.max(12, media.viewPadding.bottom + 10),
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.72),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: fxStripCardDecoration(
            sheetContext,
            radius: 28,
            glowStrength: isDark ? 0.28 : 0.48,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: line.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: BrandPalette.soft(primary, dark: isDark),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: FxIcon(name: 'route', size: 18, color: primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Todas as prioridades',
                          style: TokensStrip.h2(
                            color: primary,
                            fontFamily:
                                Theme.of(sheetContext)
                                    .textTheme
                                    .bodyLarge
                                    ?.fontFamily,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ordenadas pelo impacto de hoje.',
                          style: TokensStrip.bodyMuted(
                            color: mute,
                            fontFamily:
                                Theme.of(sheetContext)
                                    .textTheme
                                    .bodyLarge
                                    ?.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close_rounded, size: 18, color: mute),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: actions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final item = actions[index];
                    return CommandActionTile(
                      item: item,
                      isDark: isDark,
                      primary: primary,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        context.go(item.route);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

enum CommandActionTone { primary, hot, money }

Color commandToneAccent(CommandActionTone tone, Color primary) {
  return switch (tone) {
    CommandActionTone.hot => Color.lerp(EagleTokens.warn, primary, 0.34)!,
    CommandActionTone.money => const Color(0xFF0E9F6E),
    CommandActionTone.primary => primary,
  };
}

