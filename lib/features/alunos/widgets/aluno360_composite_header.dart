import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';
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

  static const _labels = ['Operação', 'Evolução', 'Ferramentas'];

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: chrome.sheetFill,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Aluno360Layout.screenPadding,
          0,
          Aluno360Layout.screenPadding,
          6,
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
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(TokensStrip.rMd),
                  border: Border.all(
                    color: line.withValues(alpha: 0.45),
                  ),
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
    this.onDelete,
    this.onHelp,
    this.actionsEnabled = true,
  });

  final String displayName;
  final bool showTitle;
  final Color ink;
  final VoidCallback onBack;
  final VoidCallback? onDelete;
  final VoidCallback? onHelp;
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
        if (onHelp != null && actionsEnabled)
          FxHelpIconButton(
            tooltip: 'Ajuda sobre esta aba',
            onTap: onHelp!,
          ),
        if (onDelete != null && actionsEnabled)
          IconButton(
            tooltip: 'Excluir aluno',
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded, color: EagleTokens.bad),
          )
        else if (onDelete != null)
          IconButton(
            onPressed: null,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: EagleTokens.bad.withValues(alpha: 0.45),
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
    this.onDelete,
    this.onHelp,
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
  final VoidCallback? onHelp;
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
    final collapsed = shrinkOffset >= heroBodyHeight * 0.85;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
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
                  onHelp: onHelp,
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
        actionsEnabled != oldDelegate.actionsEnabled ||
        onHelp != oldDelegate.onHelp;
  }
}
