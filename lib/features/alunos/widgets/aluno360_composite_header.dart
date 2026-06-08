import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../constants/aluno_360_layout.dart';

/// Tab bar for Aluno 360 (Operação · Evolução · Ferramentas).
class Aluno360DetailTabBar extends StatelessWidget {
  const Aluno360DetailTabBar({
    super.key,
    required this.tabController,
    required this.primary,
    required this.mute,
    required this.line,
  });

  final TabController tabController;
  final Color primary;
  final Color mute;
  final Color line;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Material(
      color: chrome.sheetFill,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: chrome.sheetFill,
          border: Border(bottom: BorderSide(color: line.withValues(alpha: 0.65))),
        ),
        child: Semantics(
          container: true,
          label: 'Abas do perfil do aluno',
          child: TabBar(
            controller: tabController,
            indicatorColor: primary,
            labelColor: primary,
            unselectedLabelColor: mute,
            indicatorWeight: 2,
            dividerColor: Colors.transparent,
            labelStyle: Aluno360Layout.tabSelectedLabelStyle(),
            unselectedLabelStyle: Aluno360Layout.tabUnselectedLabelStyle(),
            tabs: const [
              Tab(text: 'Operação'),
              Tab(text: 'Evolução'),
              Tab(text: 'Ferramentas'),
            ],
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
    this.onDelete,
    this.actionsEnabled = true,
  });

  final String displayName;
  final bool showTitle;
  final Color ink;
  final VoidCallback onBack;
  final VoidCallback? onDelete;
  final bool actionsEnabled;

  @override
  Widget build(BuildContext context) {
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
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Aluno360Layout.identityNameStyle(context, ink),
            ),
          )
        else
          const Spacer(),
        if (onDelete != null && actionsEnabled)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz_rounded, color: ink),
            tooltip: 'Mais opções',
            offset: const Offset(0, 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'excluir') onDelete!();
            },
            itemBuilder:
                (ctx) => [
                  PopupMenuItem<String>(
                    value: 'excluir',
                    height: 44,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: EagleTokens.bad,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Excluir aluno',
                          style: AppTypography.inter(
                            color: EagleTokens.bad,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          )
        else if (onDelete != null)
          IconButton(
            onPressed: null,
            icon: Icon(
              Icons.more_horiz_rounded,
              color: ink.withValues(alpha: 0.45),
            ),
          ),
        const ShellThemeToggle(size: 38),
        const SizedBox(width: 8),
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
    this.onDelete,
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
  final Color ink;
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback? onDelete;
  final bool actionsEnabled;

  @override
  double get minExtent =>
      topInset + kToolbarHeight + Aluno360Layout.tabBarHeight;

  @override
  double get maxExtent => minExtent + heroBodyHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final chrome = ShellChrome.of(context);
    final currentExtent = math.max(minExtent, maxExtent - shrinkOffset);
    final heroSlot = math.max(
      0.0,
      currentExtent - topInset - kToolbarHeight - Aluno360Layout.tabBarHeight,
    );
    final collapsed = shrinkOffset >= heroBodyHeight * 0.85;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Material(
        color: collapsed ? chrome.sheetFill : Colors.transparent,
        elevation: overlapsContent && collapsed ? 1 : 0,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
        child: SizedBox(
          height: currentExtent,
          child: Column(
            children: [
              SizedBox(height: topInset),
              SizedBox(
                height: kToolbarHeight,
                child: Aluno360HeaderToolbar(
                  displayName: displayName,
                  showTitle: collapsed,
                  ink: ink,
                  onBack: onBack,
                  onDelete: onDelete,
                  actionsEnabled: actionsEnabled,
                ),
              ),
              if (heroSlot > 0)
                SizedBox(
                  height: heroSlot,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Aluno360Layout.screenPadding,
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: heroChild,
                    ),
                  ),
                ),
              SizedBox(
                height: Aluno360Layout.tabBarHeight,
                child: Aluno360DetailTabBar(
                  tabController: tabController,
                  primary: primary,
                  mute: mute,
                  line: line,
                ),
              ),
            ],
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
        ink != oldDelegate.ink ||
        isDark != oldDelegate.isDark ||
        actionsEnabled != oldDelegate.actionsEnabled;
  }
}
