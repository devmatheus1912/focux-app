import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/coach_proativo_repository.dart';
import '../utils/coach_display.dart';
import '../widgets/coach_catalog_sheet.dart';
import '../widgets/coach_proativo_card.dart';

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
              return RefreshIndicator(
                color: primary,
                onRefresh: () async {
                  ref.invalidate(coachHomeProvider);
                  await ref.read(coachHomeProvider.future);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 48),
                    FxEmptyState(
                      icon: 'spark',
                      title: coachEmptyTitle,
                      subtitle: coachEmptySubtitle,
                      action: FxEmptyAction(
                        label: 'Ver alunos',
                        onTap: () {
                          AnalyticsService.instance.track(
                            ProductEvents.alunosViewed,
                          );
                          goPersonalShellTab(context, '/alunos');
                        },
                      ),
                    ),
                  ],
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
                      onChat: () {
                        context.push(coachChatRota(focus));
                      },
                      onAgenda: () {
                        final rota = coachAgendaRota(focus);
                        if (rota == null) return;
                        goPersonalShellTab(context, rota);
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
                    DashboardSectionHeader(
                      title: 'Fila',
                      actionLabel:
                          data.hasNext || data.totalItens > 3
                              ? 'Ver todos'
                              : null,
                      onAction:
                          data.hasNext || data.totalItens > 3
                              ? () {
                                showCoachCatalogSheet(
                                  context,
                                  firstPage: data,
                                  repo: CoachProativoRepository(
                                    ref.read(apiClientProvider),
                                  ),
                                );
                              }
                              : null,
                    ),
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
    required this.onChat,
    required this.onAgenda,
    required this.onAck,
  });

  final CoachHomeItem focus;
  final int pending;
  final bool isDark;
  final VoidCallback onOpen;
  final VoidCallback onChat;
  final VoidCallback onAgenda;
  final VoidCallback onAck;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final split = coachFocusActions(
      canChat: focus.alunoId > 0,
      canAgenda: coachAgendaRota(focus) != null,
    );

    VoidCallback run(CoachFocusActionId id) => switch (id) {
      CoachFocusActionId.open => onOpen,
      CoachFocusActionId.chat => onChat,
      CoachFocusActionId.agenda => onAgenda,
      CoachFocusActionId.ack => onAck,
    };

    Future<void> openMais() async {
      final chosen = await showFxInsetPickerSheet<CoachFocusActionId>(
        context,
        title: 'Mais ações',
        headerIcon: Icons.more_horiz_rounded,
        selected: null,
        items: [
          for (final id in split.secondary)
            FxInsetPickerSheetItem(
              value: id,
              label: coachFocusActionLabel(id),
            ),
        ],
      );
      if (chosen == null) return;
      HapticFeedback.selectionClick();
      run(chosen)();
    }

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
              FxActionChip(
                label: coachFocusActionLabel(split.primary),
                accent: primary,
                isDark: isDark,
                onPressed: run(split.primary),
              ),
              if (split.secondary.isNotEmpty)
                FxActionChip(
                  label: 'Mais ações',
                  accent: chrome.mute,
                  isDark: isDark,
                  onPressed: openMais,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
