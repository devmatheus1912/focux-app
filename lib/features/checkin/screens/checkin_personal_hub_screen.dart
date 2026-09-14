import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../models/checkin_personal_home.dart';
import '../providers/checkin_provider.dart';
import '../utils/checkin_personal_display.dart';
import '../widgets/checkin_personal_catalog_sheet.dart';
import '../widgets/checkin_personal_help_sheet.dart';

class CheckinPersonalHubScreen extends ConsumerStatefulWidget {
  const CheckinPersonalHubScreen({super.key});

  @override
  ConsumerState<CheckinPersonalHubScreen> createState() =>
      _CheckinPersonalHubScreenState();
}

class _CheckinPersonalHubScreenState
    extends ConsumerState<CheckinPersonalHubScreen> {
  final _openedAt = DateTime.now();
  DateTime? _fetchedAt;
  var _viewTracked = false;
  var _ttvTracked = false;
  int? _cobrandoAlunoId;

  Future<void> _cobrar(CheckinPersonalPendente pendente) async {
    if (_cobrandoAlunoId != null) return;
    setState(() => _cobrandoAlunoId = pendente.alunoId);
    try {
      await ref
          .read(alunoRepositoryProvider)
          .cobrarTreino(pendente.alunoId, treinoId: pendente.treinoId);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Lembrete enviado');
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _cobrandoAlunoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(checkinPersonalHomeProvider);
    ref.listen<AsyncValue<CheckinPersonalHomeBundle>>(
      checkinPersonalHomeProvider,
      (_, next) {
        if (!next.isLoading && next.hasValue) {
          setState(() => _fetchedAt = DateTime.now());
        }
      },
    );

    if (homeAsync.hasValue && !_viewTracked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _viewTracked) return;
        _viewTracked = true;
        final home = homeAsync.requireValue;
        AnalyticsService.instance.track(
          ProductEvents.checkinHubViewed,
          props: {'hoje': home.checkinsHoje, 'semana': home.semana.length},
        );
        if (!_ttvTracked) {
          _ttvTracked = true;
          AnalyticsService.instance.track(
            ProductEvents.checkinHubTtv,
            props: {
              'ms': DateTime.now().difference(_openedAt).inMilliseconds,
              'hoje': home.checkinsHoje,
            },
          );
        }
      });
    }

    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Check-ins',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Check-ins',
          subtitle: freshness,
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar os check-ins',
              onTap: () {
                AnalyticsService.instance.track(
                  ProductEvents.checkinHubHelpOpened,
                );
                showCheckinPersonalHelpSheet(context);
              },
            ),
          ],
        ),
        body: homeAsync.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                child: SkeletonList(count: 6),
              ),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: friendlyError(e),
                onRetry: () => ref.invalidate(checkinPersonalHomeProvider),
              ),
          data: (home) {
            if (home.hoje.isEmpty &&
                home.semana.isEmpty &&
                home.pendentes.isEmpty) {
              return FxEmptyState(
                icon: 'dumbbell',
                title: 'Nenhum check-in nesta semana',
                subtitle:
                    'Quando o aluno concluir um treino, ele aparece aqui. '
                    'A conta de hoje é a mesma do pulso da Home.',
                action: FxEmptyAction(
                  label: 'Ver alunos',
                  onTap: () => goPersonalShellTab(context, '/alunos'),
                ),
              );
            }
            return RefreshIndicator(
              color: primary,
              onRefresh: () async {
                AnalyticsService.instance.track(
                  ProductEvents.checkinHubRefreshed,
                );
                ref.invalidate(checkinPersonalHomeProvider);
                await ref.read(checkinPersonalHomeProvider.future);
              },
              child: FxContentWidthLimiter(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    TokensStrip.s3,
                    FxSettingsLayout.pageInset,
                    TokensStrip.s6,
                  ),
                  children: [
                    _CheckinTodayCard(home: home, isDark: isDark),
                    if (home.pendentes.isNotEmpty) ...[
                      const SizedBox(height: TokensStrip.s4),
                      DashboardSectionHeader(
                        title:
                            home.pendentes.length == 1
                                ? '1 aluno sem check-in hoje'
                                : '${home.pendentes.length} sem check-in hoje',
                      ),
                      const SizedBox(height: TokensStrip.s2),
                      for (final pendente in home.pendentes)
                        _CheckinPendenteTile(
                          pendente: pendente,
                          loading: _cobrandoAlunoId == pendente.alunoId,
                          onCobrar: () => _cobrar(pendente),
                        ),
                    ],
                    if (home.hoje.isNotEmpty) ...[
                      const SizedBox(height: TokensStrip.s4),
                      _CheckinSection(
                        title:
                            home.checkinsHoje == 1
                                ? '1 check-in hoje'
                                : '${home.checkinsHoje} check-ins hoje',
                        items: home.hoje,
                        home: home,
                      ),
                    ],
                    if (home.semana.isNotEmpty) ...[
                      const SizedBox(height: TokensStrip.s4),
                      _CheckinSection(
                        title: 'Últimos 6 dias',
                        items: home.semana,
                        home: home,
                      ),
                    ],
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

class _CheckinTodayCard extends StatelessWidget {
  const _CheckinTodayCard({required this.home, required this.isDark});

  final CheckinPersonalHomeBundle home;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, isDark);
    final count = home.checkinsHoje;
    return FxStripCard(
      emphasize: true,
      semanticsLabel: count == 1 ? '1 check-in hoje' : '$count check-ins hoje',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hoje', style: FocuxHubTypography.chip(chrome.mute)),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: FocuxHubTypography.kpi(
              color: chrome.ink,
              fontSize: FocuxHubTypography.metricLg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count == 0
                ? 'Ninguém concluiu treino ainda'
                : count == 1
                ? 'Treino concluído'
                : 'Treinos concluídos',
            style: FocuxHubTypography.body(
              color: chrome.ink,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: TokensStrip.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: DashboardHomeActionChip(
              label: checkinFocusAction(home).label,
              accent: Theme.of(context).colorScheme.primary,
              isDark: isDark,
              onPressed: () {
                final focus = checkinFocusAction(home);
                final alunoId = focus.alunoId;
                if (alunoId != null) {
                  context.push('/alunos/$alunoId');
                  return;
                }
                goPersonalShellTab(context, '/alunos');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckinSection extends ConsumerWidget {
  const _CheckinSection({
    required this.title,
    required this.items,
    required this.home,
  });

  final String title;
  final List<CheckinPersonalItem> items;
  final CheckinPersonalHomeBundle home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAll = home.hasNext || home.totalItens > 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(
          title: title,
          actionLabel: showAll ? 'Ver todos' : null,
          onAction:
              showAll
                  ? () => showCheckinPersonalCatalogSheet(
                    context,
                    title: title,
                    firstPage: home,
                    repo: ref.read(checkinRepositoryProvider),
                  )
                  : null,
        ),
        const SizedBox(height: TokensStrip.s2),
        for (final item in items.take(3)) _CheckinTile(item: item),
      ],
    );
  }
}

class _CheckinTile extends StatelessWidget {
  const _CheckinTile({required this.item});

  final CheckinPersonalItem item;

  @override
  Widget build(BuildContext context) {
    return FxSatelliteListTile(
      title: item.alunoNome,
      subtitle: Text(item.treinoNome),
      leading: AlunoAvatar(
        name: item.alunoNome,
        photoUrl: item.fotoUrl,
        variant: AlunoAvatarVariant.strip,
      ),
      trailing:
          item.iniciadoEm == null
              ? null
              : Text(
                fxTimeAgo(item.iniciadoEm!),
                style: FocuxHubTypography.bodyMuted(
                  color: fxScreenMute(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
      onTap: () => context.push('/alunos/${item.alunoId}'),
    );
  }
}

class _CheckinPendenteTile extends StatelessWidget {
  const _CheckinPendenteTile({
    required this.pendente,
    required this.loading,
    required this.onCobrar,
  });

  final CheckinPersonalPendente pendente;
  final bool loading;
  final VoidCallback onCobrar;

  @override
  Widget build(BuildContext context) {
    return FxSatelliteListTile(
      title: pendente.alunoNome,
      subtitle: Text(pendente.treinoNome),
      leading: AlunoAvatar(
        name: pendente.alunoNome,
        variant: AlunoAvatarVariant.strip,
      ),
      trailing: TextButton(
        onPressed: loading ? null : onCobrar,
        child: Text(loading ? 'Enviando…' : 'Cobrar treino'),
      ),
      onTap: () => context.push('/alunos/${pendente.alunoId}'),
    );
  }
}
