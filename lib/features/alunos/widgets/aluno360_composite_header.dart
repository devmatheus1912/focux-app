import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';
import '../constants/aluno_360_layout.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/aluno360_menu_acoes.dart';
import '../utils/aluno_status.dart';

/// Tab bar for Aluno 360 (Resumo · Evolução · Ferramentas).
class Aluno360DetailTabBar extends StatelessWidget {
  const Aluno360DetailTabBar({
    super.key,
    required this.tabController,
    required this.primary,
    required this.mute,
    required this.line,
    this.tabBackdropOpaque = false,
  });

  final TabController tabController;
  final Color primary;
  final Color mute;
  final Color line;
  final bool tabBackdropOpaque;

  static const _labels = ['Resumo', 'Evolução', 'Ferramentas'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Aluno360Layout.screenPadding,
        0,
        Aluno360Layout.screenPadding,
        4,
      ),
      child: AnimatedBuilder(
        animation: tabController,
        builder: (context, _) {
          return Semantics(
            container: true,
            label: 'Abas do perfil do aluno',
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(
                  alpha: tabBackdropOpaque ? 0.92 : 0.55,
                ),
                borderRadius: BorderRadius.circular(TokensStrip.rMd),
                border: Border.all(color: line.withValues(alpha: 0.45)),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _labels.length; i++)
                    Expanded(
                      child: _Aluno360TabChip(
                        label: _labels[i],
                        selected: tabController.index == i,
                        primary: primary,
                        mute: mute,
                        onTap: () {
                          if (tabController.index != i) {
                            HapticFeedback.selectionClick();
                          }
                          tabController.animateTo(i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Aluno360TabChip extends StatelessWidget {
  const _Aluno360TabChip({
    required this.label,
    required this.selected,
    required this.primary,
    required this.mute,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color primary;
  final Color mute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensStrip.rMd - 2),
          onTap: onTap,
          focusColor: primary.withValues(alpha: 0.14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? primary : Colors.transparent,
              borderRadius: BorderRadius.circular(TokensStrip.rMd - 2),
              boxShadow:
                  selected
                      ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                      : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: Aluno360Layout.tabSelectedLabelStyle().copyWith(
                  color: selected ? Colors.white : mute,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Toolbar row (back, optional title, menu, theme toggle).
class Aluno360HeaderToolbar extends StatelessWidget {
  const Aluno360HeaderToolbar({
    super.key,
    required this.displayName,
    required this.showTitle,
    required this.ink,
    required this.onBack,
    this.freshnessLabel,
    this.onChat,
    this.onHelp,
    this.menuItens = const [],
    this.onMenu,
    this.actionsEnabled = true,
  });

  final String displayName;
  final bool showTitle;
  final Color ink;
  final String? freshnessLabel;
  final VoidCallback onBack;
  final VoidCallback? onChat;
  final VoidCallback? onHelp;

  /// Itens do ⋮ (ver [aluno360MenuItens]) e o que fazer ao escolher um.
  final List<Aluno360MenuItem> menuItens;
  final ValueChanged<Aluno360MenuItem>? onMenu;
  final bool actionsEnabled;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final stamp = freshnessLabel?.trim();
    final hasStamp = stamp != null && stamp.isNotEmpty;

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
            tooltip: 'Voltar',
            onPressed: onBack,
            icon: Container(
              width: 38,
              height: 38,
              decoration: ShellChrome.of(context).headerAction(radius: 12),
              child: Icon(Icons.arrow_back_ios_new, size: 16, color: ink),
            ),
          ),
        ),
        if (showTitle)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Aluno360Layout.identityNameStyle(context, ink),
                ),
                if (hasStamp)
                  Text(
                    stamp,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Aluno360Layout.captionStyle(context),
                  ),
              ],
            ),
          )
        else if (hasStamp)
          Expanded(
            child: Text(
              stamp,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Aluno360Layout.captionStyle(context),
            ),
          )
        else
          const Spacer(),
        if (onChat != null && actionsEnabled)
          IconButton(
            tooltip: s.aluno360ChatTooltip,
            onPressed: onChat,
            icon: Icon(Icons.chat_bubble_outline_rounded, color: ink),
          ),
        if (onHelp != null && actionsEnabled)
          FxHelpIconButton(tooltip: 'Ajuda sobre esta aba', onTap: onHelp!),
        if (onMenu != null && menuItens.isNotEmpty && actionsEnabled)
          PopupMenuButton<Aluno360MenuItem>(
            tooltip: s.aluno360MenuTooltip,
            position: PopupMenuPosition.under,
            icon: Icon(Icons.more_vert_rounded, color: ink),
            onSelected: onMenu,
            itemBuilder: (_) => [
              for (final item in menuItens) ...[
                if (item.separadorAntes) const PopupMenuDivider(),
                PopupMenuItem(
                  value: item,
                  child: _MenuLinha(item: item),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _MenuLinha extends StatelessWidget {
  const _MenuLinha({required this.item});

  final Aluno360MenuItem item;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (icone, texto) = switch (item.acao) {
      Aluno360MenuAcao.editar => (Icons.edit_outlined, s.aluno360MenuEditar),
      Aluno360MenuAcao.criarTarefa => (
        Icons.playlist_add_check_rounded,
        s.aluno360MenuCriarTarefa,
      ),
      Aluno360MenuAcao.reenviarLink => (
        Icons.link_rounded,
        s.alunoReenviarLinkAcao,
      ),
      Aluno360MenuAcao.status => (
        alunoStatusIcon(item.novoStatus ?? ''),
        alunoStatusAcaoLabel(item.novoStatus ?? ''),
      ),
      Aluno360MenuAcao.excluir => (
        Icons.delete_outline_rounded,
        s.aluno360MenuExcluir,
      ),
    };
    final cor = item.destrutivo ? EagleTokens.bad : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 20, color: cor),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: cor == null ? null : TextStyle(color: cor),
          ),
        ),
      ],
    );
  }
}

/// Pinned sliver: toolbar + hero strip + tabs in one measured column.
class Aluno360CompositeHeaderDelegate extends SliverPersistentHeaderDelegate {
  const Aluno360CompositeHeaderDelegate({
    required this.topInset,
    required this.heroBodyHeight,
    required this.heroChild,
    required this.tabController,
    required this.primary,
    required this.mute,
    required this.line,
    required this.displayName,
    required this.ink,
    required this.isDark,
    required this.onBack,
    this.freshnessLabel,
    this.onChat,
    this.onHelp,
    this.menuItens = const [],
    this.onMenu,
    this.actionsEnabled = true,
  });

  final double topInset;
  final double heroBodyHeight;
  final Widget heroChild;
  final TabController tabController;
  final Color primary;
  final Color mute;
  final Color line;
  final String displayName;
  final String? freshnessLabel;
  final Color ink;
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback? onChat;
  final VoidCallback? onHelp;
  final List<Aluno360MenuItem> menuItens;
  final ValueChanged<Aluno360MenuItem>? onMenu;
  final bool actionsEnabled;

  @override
  double get minExtent =>
      topInset + kToolbarHeight + Aluno360Layout.tabBarHeight;

  @override
  double get maxExtent => minExtent + heroBodyHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final chrome = ShellChrome.of(context);
    final currentExtent = math.max(minExtent, maxExtent - shrinkOffset);
    final heroSlot = math.max(
      0.0,
      currentExtent - topInset - kToolbarHeight - Aluno360Layout.tabBarHeight,
    );
    final collapseT =
        heroBodyHeight <= 0
            ? 1.0
            : (shrinkOffset / heroBodyHeight).clamp(0.0, 1.0);
    final collapsed = collapseT >= 0.92;
    final heroOpacity = (1.0 - collapseT * 1.1).clamp(0.0, 1.0);
    final showHero = heroOpacity > 0.02 && heroSlot > 6;
    final tabBackdropOpaque = collapseT > 0.04 || overlapsContent;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Material(
        color:
            collapsed || overlapsContent
                ? chrome.sheetFill
                : Colors.transparent,
        elevation: overlapsContent && collapsed ? 1 : 0,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
        child: SizedBox(
          height: currentExtent,
          child: ClipRect(
            child: Column(
              children: [
                SizedBox(height: topInset),
                SizedBox(
                  height: kToolbarHeight,
                  child: Aluno360HeaderToolbar(
                    displayName: displayName,
                    showTitle: collapsed,
                    freshnessLabel: freshnessLabel,
                    ink: ink,
                    onBack: onBack,
                    onChat: onChat,
                    onHelp: onHelp,
                    menuItens: menuItens,
                    onMenu: onMenu,
                    actionsEnabled: actionsEnabled,
                  ),
                ),
                if (showHero)
                  SizedBox(
                    height: heroSlot,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        heightFactor: 1,
                        child: Opacity(
                          opacity: heroOpacity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Aluno360Layout.screenPadding,
                            ),
                            child: heroChild,
                          ),
                        ),
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        tabBackdropOpaque
                            ? chrome.sheetFill
                            : Colors.transparent,
                  ),
                  child: SizedBox(
                    height: Aluno360Layout.tabBarHeight,
                    child: Aluno360DetailTabBar(
                      tabController: tabController,
                      primary: primary,
                      mute: mute,
                      line: line,
                      tabBackdropOpaque: tabBackdropOpaque,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant Aluno360CompositeHeaderDelegate oldDelegate) {
    return topInset != oldDelegate.topInset ||
        heroBodyHeight != oldDelegate.heroBodyHeight ||
        heroChild != oldDelegate.heroChild ||
        tabController != oldDelegate.tabController ||
        primary != oldDelegate.primary ||
        mute != oldDelegate.mute ||
        line != oldDelegate.line ||
        displayName != oldDelegate.displayName ||
        freshnessLabel != oldDelegate.freshnessLabel ||
        ink != oldDelegate.ink ||
        isDark != oldDelegate.isDark ||
        actionsEnabled != oldDelegate.actionsEnabled ||
        onHelp != oldDelegate.onHelp ||
        onChat != oldDelegate.onChat ||
        !listEquals(menuItens, oldDelegate.menuItens);
  }
}
