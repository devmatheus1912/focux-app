import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_rive_player.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/gamificacao_repository.dart';
import '../models/gamificacao_badge_tile.dart';
import '../providers/gamificacao_provider.dart';
import '../utils/gamificacao_display.dart';

class GamificacaoScreen extends ConsumerWidget {
  const GamificacaoScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(gamificacaoProvider);
    await ref.read(gamificacaoProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final async = ref.watch(gamificacaoProvider);

    return fxScreenA11yScope(
      label: 'Minha evolução',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Minha evolução',
          onBack: () => safePopOrGo(context, '/perfil/ferramentas'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como funciona a evolução',
              onTap: () => showFxHelpSheet(
                context,
                title: 'Evolução',
                subtitle: 'Sequência, PRs e conquistas do treino.',
                tips: const [
                  FxHelpTip('Como calculamos', gamificacaoComoCalculamos),
                  FxHelpTip('Conquistas', 'As 3 do topo. Ver mais abre o restante.'),
                  FxHelpTip('Indicação', 'O código de amigo continua em Referral.'),
                ],
              ),
            ),
          ],
        ),
        body: async.when(
          loading: () => const SkeletonList(count: 5),
          error: (e, _) => FxErrorState(
            chromeOnDark: isDark,
            primary: primary,
            message: friendlyError(e),
            onRetry: () => _refresh(ref),
          ),
          data: (data) {
            final empty = data.totalTreinos == 0 && data.badges.isEmpty;
            return RefreshIndicator(
              color: primary,
              onRefresh: () => _refresh(ref),
              child: empty
                  ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 48),
                      FxEmptyState(
                        icon: 'spark',
                        title: 'Sua evolução começa no treino',
                        subtitle:
                            'Conquistas e sequência aparecem aqui depois do primeiro treino.',
                        action: FxEmptyAction(
                          label: 'Ir para o Hoje',
                          onTap: () => goPersonalShellTab(
                            context,
                            '/dashboard/personal',
                          ),
                        ),
                      ),
                    ],
                  )
                  : FxContentWidthLimiter(
                    child: _GamificacaoBody(data: data, isDark: isDark),
                  ),
            );
          },
        ),
      ),
    );
  }
}

class _GamificacaoBody extends StatefulWidget {
  const _GamificacaoBody({required this.data, required this.isDark});

  final GamificacaoData data;
  final bool isDark;

  @override
  State<_GamificacaoBody> createState() => _GamificacaoBodyState();
}

class _GamificacaoBodyState extends State<_GamificacaoBody> {
  var _mostrarTodas = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isDark = widget.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final badges = buildGamificacaoBadgeTiles(
      data,
      primary,
      TokensStrip.textSecondary,
    );
    final visiveis =
        _mostrarTodas ? badges : gamificacaoBadgePreview(badges);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(TokensStrip.s4),
      children: [
        _StreakCard(data: data, isDark: isDark),
        const SizedBox(height: TokensStrip.s4),
        OperationalMetricTile(
          label: 'Aderência',
          value: '${data.aderenciaPercent}%',
          hint: '${data.totalTreinos} treinos',
          color: primary,
          isDark: isDark,
        ),
        const SizedBox(height: TokensStrip.s2),
        OperationalMetricTile(
          label: 'PRs no mês',
          value: '${data.prsEsseMes}',
          hint: 'Recorde ${data.streak.streakMaximo}d',
          color: EagleTokens.moneyGreen,
          isDark: isDark,
        ),
        const SizedBox(height: TokensStrip.s4),
        DashboardSectionHeader(
          title: 'Conquistas',
          actionLabel: badges.length > 3 && !_mostrarTodas ? 'Ver mais' : null,
          onAction: badges.length > 3 && !_mostrarTodas
              ? () => setState(() => _mostrarTodas = true)
              : null,
        ),
        const SizedBox(height: TokensStrip.s2),
        for (final badge in visiveis) _BadgeRow(badge: badge),
        const SizedBox(height: TokensStrip.s4),
        FxSatelliteListTile(
          title: 'Indique um amigo',
          subtitle: const Text('30 dias extras quando ele assinar.'),
          onTap: () => context.push('/referral'),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.data, required this.isDark});

  final GamificacaoData data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final streak = data.streak.streakAtual;
    return FxStripCard(
      emphasize: true,
      semanticsLabel: 'Sequência ${gamificacaoStreakLabel(streak)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sequência', style: FocuxHubTypography.chip(chrome.mute)),
          const SizedBox(height: 6),
          Text(
            gamificacaoStreakLabel(streak),
            style: FocuxHubTypography.kpi(
              color: chrome.ink,
              fontSize: FocuxHubTypography.metricLg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            streak == 0
                ? 'Um treino hoje recomeça a série'
                : 'Recorde ${data.streak.streakMaximo}d',
            style: FocuxHubTypography.body(
              color: chrome.ink,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: TokensStrip.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: DashboardHomeActionChip(
              label: 'Ver check-in',
              accent: Theme.of(context).colorScheme.primary,
              isDark: isDark,
              onPressed: () => goPersonalShellTab(context, '/checkin'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.badge});

  final GamificacaoBadgeTile badge;

  @override
  Widget build(BuildContext context) {
    return FxSatelliteListTile(
      title: badge.label,
      subtitle: Text(badge.earned ? 'Conquistada' : 'Ainda não'),
      leading: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (badge.earned) const FxRiveBadgeGlow(size: 36),
            Text(badge.icon, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
