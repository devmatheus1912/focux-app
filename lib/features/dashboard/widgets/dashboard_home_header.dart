import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../notificacoes/data/notificacoes_repository.dart';
import '../../notificacoes/widgets/notificacao_badge_button.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';
import '../utils/dashboard_screen_helpers.dart';
import 'dashboard_header_profile_avatar.dart';

/// Header Home compacto — identidade 2 linhas + rail curto (chrome recede).
class DashboardHomeHeader extends ConsumerWidget {
  const DashboardHomeHeader({
    super.key,
    required this.nomePersonal,
    required this.logoUrl,
    required this.isDark,
    required this.primary,
    required this.onProfileTap,
    required this.focusMode,
    required this.onToggleFocus,
    this.notificacoesCountOverride,
    this.onQuickSearch,
    this.onHelp,
    this.freshnessLabel,
  });

  final String? nomePersonal;
  final String? logoUrl;
  final bool isDark;
  final Color primary;
  final VoidCallback onProfileTap;
  final bool focusMode;
  final VoidCallback onToggleFocus;
  final int? notificacoesCountOverride;
  final VoidCallback? onQuickSearch;
  final VoidCallback? onHelp;
  final String? freshnessLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dashboardReadableCaption(context, isDark: isDark);
    final firstName = dashboardPersonalFirstName(nomePersonal);
    final fullName = (nomePersonal ?? '').trim();
    final a11yName =
        fullName.isEmpty
            ? dashboardPersonalDisplayName(nomePersonal)
            : fxTitleCaseName(fullName);
    final compact = MediaQuery.sizeOf(context).width < 360;
    final live = ref.watch(notificacoesNaoLidasProvider).valueOrNull;
    final notifCount = notificacoesCountOverride ?? live ?? 0;

    final railBg =
        isDark ? const Color(0xFF070E14) : const Color(0xFF0F1720);
    final railBorder = primary.withValues(alpha: isDark ? 0.22 : 0.14);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s4,
        TokensStrip.s3,
      ),
      child: DecoratedBox(
        decoration: fxStripCardDecoration(
          context,
          accent: primary,
          radius: TokensStrip.rCard,
          glowStrength: 0.05,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    button: true,
                    label: '$a11yName. Abrir perfil',
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        DashboardHeaderProfileAvatar(
                          primary: primary,
                          isDark: isDark,
                          photoUrl: logoUrl,
                          initials: fxInitials(nomePersonal ?? 'F'),
                          size: 44,
                          onTap: onProfileTap,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isDark
                                        ? EagleTokens.darkCard
                                        : TokensStrip.cardBg,
                                width: 1.75,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Olá, $firstName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: dashboardPageTitleStyle(
                            context,
                            color: ink,
                          ).copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            style: dashboardCardSubtitleStyle(
                              context,
                              isDark: isDark,
                            ).copyWith(
                              color: mute,
                              height: 1.2,
                            ),
                            children: [
                              const TextSpan(
                                text: DashboardMicrocopy.headerTaglineLead,
                              ),
                              TextSpan(
                                text: DashboardMicrocopy.headerTaglineAccent,
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const TextSpan(
                                text: DashboardMicrocopy.headerTaglineTail,
                              ),
                              if (!compact &&
                                  freshnessLabel != null &&
                                  freshnessLabel!.isNotEmpty) ...[
                                TextSpan(
                                  text: ' · ',
                                  style: TextStyle(
                                    color: mute.withValues(alpha: 0.55),
                                  ),
                                ),
                                TextSpan(
                                  text: freshnessLabel,
                                  style: TextStyle(
                                    color: mute.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (compact &&
                            freshnessLabel != null &&
                            freshnessLabel!.isNotEmpty)
                          Semantics(
                            liveRegion: true,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(
                                freshnessLabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: dashboardCardSubtitleStyle(
                                  context,
                                  isDark: isDark,
                                ).copyWith(
                                  color: mute.withValues(alpha: 0.8),
                                  height: 1.15,
                                ),
                              ),
                            ),
                          )
                        else if (!compact &&
                            freshnessLabel != null &&
                            freshnessLabel!.isNotEmpty)
                          Semantics(
                            liveRegion: true,
                            container: false,
                            label: freshnessLabel,
                            child: const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HeaderThemeSquare(primary: primary, isDark: isDark),
                ],
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: railBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: railBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.28 : 0.14,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 58,
                  child: Row(
                    children: [
                      if (onQuickSearch != null)
                        Expanded(
                          child: _HeaderRailAction(
                            icon: 'search',
                            label: DashboardMicrocopy.headerRailBuscar,
                            primary: primary,
                            onTap: onQuickSearch!,
                          ),
                        ),
                      if (onQuickSearch != null && onHelp != null)
                        const _HeaderRailDivider(),
                      if (onHelp != null)
                        Expanded(
                          child: _HeaderRailAction(
                            icon: 'help',
                            label: DashboardMicrocopy.headerRailAjuda,
                            primary: primary,
                            tooltip: DashboardMicrocopy.helpHomeOpen,
                            onTap: onHelp!,
                          ),
                        ),
                      if (onHelp != null) const _HeaderRailDivider(),
                      Expanded(
                        child: _HeaderRailAction(
                          icon: focusMode ? 'zap' : 'moon',
                          label: DashboardMicrocopy.modoFoco,
                          primary: primary,
                          active: focusMode,
                          semanticLabel:
                              focusMode
                                  ? DashboardMicrocopy.modoFocoOn
                                  : DashboardMicrocopy.modoFocoOff,
                          onTap: onToggleFocus,
                        ),
                      ),
                      const _HeaderRailDivider(),
                      Expanded(
                        child: _HeaderRailAction(
                          icon: 'bell',
                          label: DashboardMicrocopy.headerRailNotif,
                          primary: primary,
                          badgeCount: notifCount,
                          tooltip: notificacaoBadgeTooltip(notifCount),
                          onTap: () => context.push('/notificacoes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderThemeSquare extends ConsumerWidget {
  const _HeaderThemeSquare({required this.primary, required this.isDark});

  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chrome = ShellChrome.forDark(isDark);
    return Tooltip(
      message: isDark ? 'Modo claro' : 'Modo escuro',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            width: 36,
            height: 36,
            decoration: chrome.headerAction(radius: 10),
            child: Center(
              child: FxIcon(
                name: isDark ? 'sun' : 'moon',
                size: 16,
                color: primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderRailDivider extends StatelessWidget {
  const _HeaderRailDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        width: 1,
        child: ColoredBox(color: Colors.white.withValues(alpha: 0.10)),
      ),
    );
  }
}

class _HeaderRailAction extends StatelessWidget {
  const _HeaderRailAction({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
    this.active = false,
    this.badgeCount = 0,
    this.tooltip,
    this.semanticLabel,
  });

  final String icon;
  final String label;
  final Color primary;
  final VoidCallback onTap;
  final bool active;
  final int badgeCount;
  final String? tooltip;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 22,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (active)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.5),
                              blurRadius: 12,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                        child: const SizedBox(width: 18, height: 18),
                      )
                    else
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.18),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const SizedBox(width: 16, height: 16),
                      ),
                    FxIcon(
                      name: icon,
                      size: 16,
                      color: Colors.white.withValues(
                        alpha: active ? 1 : 0.88,
                      ),
                      strokeWidth: active ? 2.05 : 1.65,
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        top: -3,
                        right: -2,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 15,
                            minHeight: 13,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFF0F1720),
                              width: 1.1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: active ? 1 : 0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      toggled: semanticLabel != null ? active : null,
      label: semanticLabel ?? label,
      child: tooltip == null ? child : Tooltip(message: tooltip!, child: child),
    );
  }
}
