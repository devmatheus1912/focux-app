import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/coach_proativo_repository.dart';
import '../utils/coach_display.dart';

final coachHomeProvider = FutureProvider.autoDispose<CoachHome>((ref) {
  return CoachProativoRepository(ref.read(apiClientProvider)).getHome();
});

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final home = ref.watch(coachHomeProvider);

    return fxScreenA11yScope(
      label: 'Coach proativo',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Coach',
          subtitle: home.maybeWhen(
            data: (data) => FxHubFreshness.fromFetchedAt(data.fetchedAt),
            orElse: () => 'Orientações automáticas',
          ),
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar o coach',
              onTap:
                  () => showFxHelpSheet(
                    context,
                    title: 'Coach',
                    subtitle: 'O que merece atenção agora.',
                    tips: const [
                      FxHelpTip('Como calculamos', coachComoCalculamos),
                      FxHelpTip(
                        'Pendente',
                        'O card do topo é a próxima orientação.',
                      ),
                      FxHelpTip(
                        'Abrir aluno',
                        'O job é ir ao aluno. Entendi só arquiva a fila.',
                      ),
                    ],
                  ),
            ),
          ],
        ),
        body: home.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.all(TokensStrip.s4),
                child: SkeletonList(count: 3),
              ),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: friendlyError(e),
                onRetry: () => ref.invalidate(coachHomeProvider),
              ),
          data: (data) {
            if (data.isEmpty) {
              return FxEmptyState(
                icon: 'spark',
                title: 'Nenhuma orientação agora',
                subtitle:
                    'O coach avisa aqui quando encontrar algo que merece sua atenção.',
                action: FxEmptyAction(
                  label: 'Ir para o Hoje',
                  onTap:
                      () => goPersonalShellTab(context, '/dashboard/personal'),
                ),
              );
            }
            final focus = data.focus ?? data.fila.first;
            return RefreshIndicator(
              color: primary,
              onRefresh: () async {
                ref.invalidate(coachHomeProvider);
                await ref.read(coachHomeProvider.future);
              },
              child: FxContentWidthLimiter(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(TokensStrip.s4),
                  children: [
                    _CoachFocusCard(
                      focus: focus,
                      pending: data.pending,
                      isDark: isDark,
                      onOpen: () {
                        context.push(coachRota(focus));
                      },
                      onAck: () async {
                        AnalyticsService.instance.track(
                          ProductEvents.homeCoachDismissed,
                        );
                        await CoachProativoRepository(
                          ref.read(apiClientProvider),
                        ).marcarLido(focus.id);
                        ref.invalidate(coachHomeProvider);
                        ref.invalidate(alunoDashboardHomeProvider);
                      },
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    const DashboardSectionHeader(title: 'Fila'),
                    const SizedBox(height: TokensStrip.s2),
                    for (final item in data.fila)
                      FxSatelliteListTile(
                        title: item.alunoNome,
                        subtitle: Text(item.mensagem),
                        onTap: () => context.push(coachRota(item)),
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

class _CoachFocusCard extends StatelessWidget {
  const _CoachFocusCard({
    required this.focus,
    required this.pending,
    required this.isDark,
    required this.onOpen,
    required this.onAck,
  });

  final CoachHomeItem focus;
  final int pending;
  final bool isDark;
  final VoidCallback onOpen;
  final VoidCallback onAck;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    return FxStripCard(
      emphasize: true,
      semanticsLabel: 'Próxima orientação. $pending pendentes.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pending == 0 ? 'Em dia' : 'Pendente',
            style: FocuxHubTypography.chip(chrome.mute),
          ),
          const SizedBox(height: 6),
          Text(
            '$pending',
            style: FocuxHubTypography.kpi(
              color: chrome.ink,
              fontSize: FocuxHubTypography.metricLg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            focus.alunoNome,
            style: FocuxHubTypography.body(
              color: chrome.ink,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            focus.mensagem,
            style: FocuxHubTypography.body(color: chrome.mute),
          ),
          const SizedBox(height: TokensStrip.s3),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              DashboardHomeActionChip(
                label: 'Abrir aluno',
                accent: Theme.of(context).colorScheme.primary,
                isDark: isDark,
                onPressed: onOpen,
              ),
              DashboardHomeActionChip(
                label: 'Entendi',
                accent: chrome.mute,
                isDark: isDark,
                onPressed: onAck,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
