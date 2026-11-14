import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';
import '../constants/aluno_360_layout.dart';
import 'aluno_form_choices.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/fx_icons.dart';

/// Tab bar for Aluno 360 (Resumo · Evolução · Ferramentas).
class Aluno360DetailTabBar extends StatelessWidget {
  const Aluno360DetailTabBar({
    super.key,
    required this.tabController,
    this.tabBackdropOpaque = false,
  });

  final TabController tabController;
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
            // Mesmo seletor do Financeiro e das outras abas do app.
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tabBackdropOpaque
                    ? scheme.surface.withValues(alpha: 0.92)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(TokensStrip.rSm),
              ),
              child: AlunoSegmentedChoice(
                options: [
                  for (var i = 0; i < _labels.length; i++)
                    (value: '$i', label: _labels[i]),
                ],
                selected: '${tabController.index}',
                isDark: Theme.of(context).brightness == Brightness.dark,
                onSelect: (v) => tabController.animateTo(int.parse(v)),
              ),
            ),
          );
        },
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

  /// Abre a folha do ⋮ (ver `showAluno360MenuSheet`).
  final VoidCallback? onMenu;
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
              child: Icon(FxIcons.voltarPequeno, size: 16, color: ink),
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
          _AcaoDoTopo(
            tooltip: s.aluno360ChatTooltip,
            icone: FxIcons.chat,
            ink: ink,
            onPressed: onChat!,
          ),
        if (onHelp != null && actionsEnabled)
          FxHelpIconButton(
            tooltip: 'Ajuda sobre esta aba',
            onTap: onHelp!,
            size: 38,
            expandHitTarget: true,
          ),
        if (onMenu != null && actionsEnabled)
          _AcaoDoTopo(
            tooltip: s.aluno360MenuTooltip,
            icone: FxIcons.mais,
            ink: ink,
            onPressed: onMenu!,
          ),
        const SizedBox(width: TokensStrip.s1),
      ],
    );
  }
}

/// Ação do topo: mesmo tamanho e estilo do voltar.
class _AcaoDoTopo extends StatelessWidget {
  const _AcaoDoTopo({
    required this.tooltip,
    required this.icone,
    required this.ink,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icone;
  final Color ink;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      icon: Container(
        width: 38,
        height: 38,
        decoration: ShellChrome.of(context).headerAction(radius: 19),
        child: Icon(icone, size: 18, color: ink),
      ),
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
  final VoidCallback? onMenu;
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
    // Some antes de ser cortado: card de cor pela metade fica quebrado.
    final heroOpacity = (1.0 - collapseT * 2.2).clamp(0.0, 1.0);
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
                            padding: const EdgeInsets.fromLTRB(
                              Aluno360Layout.screenPadding,
                              TokensStrip.s1,
                              Aluno360Layout.screenPadding,
                              TokensStrip.s2,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: heroChild,
                            ),
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
        (onMenu == null) != (oldDelegate.onMenu == null);
  }
}
