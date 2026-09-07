import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
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
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/analytics_repository.dart';
import '../providers/analytics_provider.dart';
import '../utils/analytics_display.dart';

part 'analytics_screen_widgets.part.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  DateTime? _fetchedAt;
  ProviderSubscription<AsyncValue<AnalyticsDashboard>>? _freshnessSub;

  @override
  void initState() {
    super.initState();
    _freshnessSub = ref.listenManual(analyticsDashboardProvider, (
      _,
      next,
    ) {
      if (!next.hasValue || next.isLoading || next.hasError) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _fetchedAt = DateTime.now());
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _freshnessSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    final async = ref.watch(analyticsDashboardProvider);
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Analytics',
      child: FxShellScaffold(
        constrainWidth: false,
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Analytics',
          subtitle:
              freshnessLabel ??
              FxHubFreshness.fromFetchedAt(
                async.asData?.value.fetchedAt,
              ),
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar Analytics',
              onTap:
                  () => showFxHelpSheet(
                    context,
                    title: 'Analytics',
                    subtitle: 'Pulso da base: atividade, churn e retenção.',
                    tips: const [
                      FxHelpTip('Como calculamos', analyticsComoCalculamos),
                      FxHelpTip(
                        'Churn',
                        'O card do topo é a inadimplência. Funil e WAU vêm do mesmo BFF.',
                      ),
                      FxHelpTip(
                        'Ação',
                        'Financeiro cobra atraso. Retenção mostra quem pode sair.',
                      ),
                    ],
                  ),
            ),
          ],
        ),
        body: FxContentWidthLimiter(
          child: async.when(
            loading: () => const SkeletonList(count: 6),
            error:
                (e, _) => FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: friendlyError(e),
                  onRetry: () => ref.invalidate(analyticsDashboardProvider),
                ),
            data: (data) {
              if (data.totalAlunos == 0) {
                return RefreshIndicator(
                  color: primary,
                  onRefresh: () async =>
                      ref.invalidate(analyticsDashboardProvider),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 48),
                      FxEmptyState(
                        icon: 'bar-chart-2',
                        title: 'Sem dados ainda',
                        subtitle:
                            'Cadastre alunos para ver analytics operacional da base.',
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
              return RefreshIndicator(
                color: primary,
                onRefresh:
                    () async => ref.invalidate(analyticsDashboardProvider),
                child: _AnalyticsBody(data: data, dark: dark),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────
