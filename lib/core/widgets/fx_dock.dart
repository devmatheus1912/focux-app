import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/fx_settings_layout.dart';
import '../theme/tokens_strip.dart';
import '../../l10n/app_localizations.dart';
import 'fx_icon.dart';

/// Tom do selo: `alerta` pede ação (vermelho); `info` só informa (cor da marca).
enum FxDockBadgeTone { alerta, info }

class FxDockItem {
  final String icon;
  final String label;
  final int badgeCount;
  final FxDockBadgeTone badgeTone;

  /// Texto lido pelo leitor de tela junto do nome ("3 não lidas").
  final String? badgeLabel;

  const FxDockItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    this.badgeTone = FxDockBadgeTone.alerta,
    this.badgeLabel,
  });
}

class FxDockItems {
  static List<FxDockItem> personal(
    S s, {
    int alunosEmRisco = 0,
    int agendaHoje = 0,
  }) => [
    FxDockItem(icon: 'home', label: s.dockHoje),
    FxDockItem(
      icon: 'users',
      label: s.dockAlunos,
      badgeCount: alunosEmRisco,
      badgeLabel: alunosEmRisco > 0 ? s.dockBadgeEmRisco(alunosEmRisco) : null,
    ),
    FxDockItem(icon: 'dumbbell', label: s.dockTreinos),
    FxDockItem(
      icon: 'calendar',
      label: s.dockAgenda,
      badgeCount: agendaHoje,
      badgeTone: FxDockBadgeTone.info,
      badgeLabel: agendaHoje > 0 ? s.dockBadgeHoje(agendaHoje) : null,
    ),
    FxDockItem(icon: 'spark', label: s.dockIa),
  ];

  static List<FxDockItem> aluno(S s, {int chatUnread = 0}) => [
    FxDockItem(icon: 'home', label: s.dockHoje),
    FxDockItem(icon: 'dumbbell', label: s.dockTreinos),
    FxDockItem(icon: 'heart-pulse', label: s.dockSaude),
    FxDockItem(
      icon: 'chat',
      label: s.dockChat,
      badgeCount: chatUnread,
      badgeLabel: chatUnread > 0 ? s.dockBadgeNaoLidas(chatUnread) : null,
    ),
    FxDockItem(icon: 'user', label: s.dockPerfil),
  ];
}

/// Dock flutuante — glass da marca, anatomia de tab bar iOS (sem poço/underline).
class FxDock extends StatelessWidget {
  const FxDock({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
    this.cinematicChrome = false,
  });

  final List<FxDockItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  final bool cinematicChrome;

  static const double floatGap = 10;
  static const double sideInset = FxSettingsLayout.pageInset;

  static double barHeight({required bool compact}) => compact ? 62 : 64;

  static double shellClearance({
    required double bottomInset,
    required bool compact,
  }) => bottomInset + floatGap + barHeight(compact: compact) + 8;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;

    final surface = TokensStrip.glassFill(
      dark: isDark,
      opacity: isDark ? (cinematicChrome ? 0.88 : 0.92) : 0.94,
    );
    final border = TokensStrip.glassBorder(
      dark: isDark,
      accent: primary,
    ).withValues(alpha: isDark ? 0.36 : 0.40);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.08),
              blurRadius: isDark ? 18 : 14,
              offset: const Offset(0, 6),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
          child: _dockSurface(
            context: context,
            isDark: isDark,
            surface: surface,
            border: border,
            primary: primary,
            compact: compact,
          ),
        ),
      ),
    );
  }

  Widget _dockSurface({
    required BuildContext context,
    required bool isDark,
    required Color surface,
    required Color border,
    required Color primary,
    required bool compact,
  }) {
    final reduceMotion = TokensStrip.prefersReducedMotion(context);
    final body = DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TokensStrip.s1,
          vertical: 6,
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            return Expanded(
              child: _FxDockNavItem(
                item: items[i],
                active: i == currentIndex,
                isDark: isDark,
                primary: primary,
                compact: compact,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(i);
                },
              ),
            );
          }),
        ),
      ),
    );
    if (reduceMotion) return body;
    return BackdropFilter(
      filter: TokensStrip.blurFilter(TokensStrip.blurLight),
      child: body,
    );
  }
}

class _FxDockNavItem extends StatefulWidget {
  const _FxDockNavItem({
    required this.item,
    required this.active,
    required this.isDark,
    required this.primary,
    required this.compact,
    required this.onTap,
  });

  final FxDockItem item;
  final bool active;
  final bool isDark;
  final Color primary;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_FxDockNavItem> createState() => _FxDockNavItemState();
}

class _FxDockNavItemState extends State<_FxDockNavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final inactive =
        widget.isDark
            ? const Color(0xFFA9B4C0)
            : const Color(0xFF51606B);
    final color = widget.active ? widget.primary : inactive;
    final reduceMotion = TokensStrip.prefersReducedMotion(context);
    final item = widget.item;
    final semantica =
        item.badgeLabel == null
            ? item.label
            : '${item.label}, ${item.badgeLabel}';

    return Semantics(
      button: true,
      selected: widget.active,
      label: semantica,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
          splashColor: widget.primary.withValues(alpha: 0.08),
          highlightColor: widget.primary.withValues(alpha: 0.04),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // pílula tonal: o estado ativo não depende só da cor do ícone
                    AnimatedContainer(
                      duration:
                          reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      width: 52,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            widget.active
                                ? widget.primary.withValues(
                                  alpha: widget.isDark ? 0.24 : 0.14,
                                )
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          FxIcon(
                            name: item.icon,
                            size: FxSettingsLayout.iconSize,
                            color: color,
                            strokeWidth: widget.active ? 2.0 : 1.7,
                          ),
                          if (item.badgeCount > 0)
                            Positioned(
                              right: -10,
                              top: -7,
                              child: _DockBadge(
                                count: item.badgeCount,
                                tone: item.badgeTone,
                                primary: widget.primary,
                                isDark: widget.isDark,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: FocuxHubTypography.chip(color).copyWith(
                        fontSize: widget.compact ? 11.0 : 11.5,
                        fontWeight:
                            widget.active ? FontWeight.w700 : FontWeight.w500,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockBadge extends StatelessWidget {
  const _DockBadge({
    required this.count,
    required this.tone,
    required this.primary,
    required this.isDark,
  });

  final int count;
  final FxDockBadgeTone tone;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fill = tone == FxDockBadgeTone.alerta ? EagleTokens.bad : primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? const Color(0xFF14161A) : Colors.white,
          width: 1.5,
        ),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}
